import SwiftUI
import PhotosUI

struct AssistantView: View {
    @EnvironmentObject private var appState: AppState
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isTyping = false
    @State private var showImagePicker = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var showQuickPrompts = true
    @State private var navigateToDoctorDetail: DoctorDetail?
    @FocusState private var inputFocused: Bool

    private let aiProvider: AIProviderProtocol = AIProviderFactory.make()

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                AppTheme.bg.ignoresSafeArea()
                VStack(spacing: 0) {
                    chatList
                    inputBar
                }
            }
            .navigationTitle(Loc.assistant)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .navigationDestination(item: $navigateToDoctorDetail) { doc in
                DoctorProfileView(doctor: doc)
            }
        }
        .onAppear { if messages.isEmpty { resetChat() } }
        .onChange(of: appState.language) { _, _ in resetChat() }
        .onChange(of: selectedItem) { _, item in handlePhotoSelection(item) }
    }

    // MARK: - Chat List
    private var chatList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if showQuickPrompts && messages.count <= 1 {
                        quickPromptsGrid
                            .padding(.top, 8)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    ForEach(messages) { msg in
                        ChatBubble(message: msg, onBookDoctor: { doctor in
                            navigateToDoctorDetail = doctor
                        })
                        .id(msg.id)
                    }
                    if isTyping { TypingIndicator() }
                    Color.clear.frame(height: 80).id("bottom")
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
            .onChange(of: messages.count) { _, _ in
                withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
            }
            .onChange(of: isTyping) { _, val in
                if val { withAnimation { proxy.scrollTo("bottom", anchor: .bottom) } }
            }
        }
    }

    // MARK: - Quick Prompts Grid
    private var quickPromptsGrid: some View {
        VStack(alignment: .trailing, spacing: 10) {
            let label = Loc.lang == .arabic ? "ابدأ بسؤال سريع" : "Начните с быстрого вопроса"
            Text(label)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
            let columns = [GridItem(.flexible()), GridItem(.flexible())]
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(AIPrompts.quickPrompts) { prompt in
                    QuickPromptChip(prompt: prompt) {
                        sendText(prompt.displayText)
                        withAnimation { showQuickPrompts = false }
                    }
                }
            }
        }
    }

    // MARK: - Input Bar
    private var inputBar: some View {
        HStack(spacing: 10) {
            PhotosPicker(selection: $selectedItem, matching: .images) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 20))
                    .foregroundStyle(AppTheme.primary)
                    .frame(width: 40, height: 40)
                    .background(AppTheme.primarySoft)
                    .clipShape(Circle())
            }
            HStack {
                let placeholder = Loc.lang == .arabic ? "اكتب أعراضك أو سؤالك..." : "Опишите симптомы или задайте вопрос..."
                TextField(placeholder, text: $inputText, axis: .vertical)
                    .font(.body)
                    .lineLimit(1...4)
                    .focused($inputFocused)
                    .multilineTextAlignment(Loc.lang == .arabic ? .trailing : .leading)
                if !inputText.isEmpty {
                    Button { inputText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(inputFocused ? AppTheme.primary.opacity(0.5) : Color.clear, lineWidth: 1.5)
            )
            Button { sendCurrent() } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(inputText.trimmingCharacters(in: .whitespaces).isEmpty
                                     ? Color.gray.opacity(0.3) : AppTheme.primary)
            }
            .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    // MARK: - Toolbar
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                withAnimation { resetChat() }
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.primary)
            }
        }
        ToolbarItem(placement: .topBarLeading) {
            HStack(spacing: 6) {
                Circle().fill(AppTheme.success).frame(width: 8, height: 8)
                let label = Loc.lang == .arabic ? "متصل" : "Онлайн"
                Text(label).font(.caption.weight(.medium)).foregroundStyle(AppTheme.success)
            }
        }
    }

    // MARK: - Actions
    private func resetChat() {
        messages = SampleConversation.welcomeMessages(language: appState.language)
        showQuickPrompts = true
    }

    private func sendCurrent() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        inputText = ""
        sendText(text)
    }

    private func sendText(_ text: String) {
        withAnimation { showQuickPrompts = false }
        let userMsg = ChatMessage(sender: .user, content: .text(text), timestamp: Date())
        messages.append(userMsg)
        isTyping = true
        Task {
            let response = await aiProvider.generateMedicalResponse(query: text, language: appState.language)
            await MainActor.run { handleAIResponse(response) }
        }
    }

    private func handleAIResponse(_ response: AIResponse) {
        isTyping = false

        if response.isEmergency {
            let msg = ChatMessage(sender: .assistant, content: .emergencyAlert(response.text), timestamp: Date())
            withAnimation { messages.append(msg) }
            return
        }

        if let card = response.analysisCard {
            let msg = ChatMessage(sender: .assistant, content: .analysisResult(card), timestamp: Date())
            withAnimation { messages.append(msg) }
        } else {
            let msg = ChatMessage(sender: .assistant, content: .text(response.text), timestamp: Date())
            withAnimation { messages.append(msg) }
        }

        if !response.suggestedDoctors.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let suggMsg = ChatMessage(
                    sender: .assistant,
                    content: .doctorSuggestions(response.suggestedDoctors),
                    timestamp: Date()
                )
                withAnimation { self.messages.append(suggMsg) }
            }
        }
    }

    private func handlePhotoSelection(_ item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let img = UIImage(data: data) {
                await MainActor.run { appendImageMessage(img) }
            }
        }
    }

    private func appendImageMessage(_ img: UIImage) {
        let caption = Loc.lang == .arabic ? "صورة للتحليل" : "Изображение для анализа"
        let userMsg = ChatMessage(sender: .user, content: .image(img, caption: caption), timestamp: Date())
        messages.append(userMsg)
        isTyping = true
        Task {
            let analysis = await aiProvider.analyzeImage(img, language: appState.language)
            await MainActor.run { handleImageAnalysis(analysis) }
        }
    }

    private func handleImageAnalysis(_ analysis: AIImageAnalysis) {
        isTyping = false
        if analysis.category == .nonMedical, let reject = analysis.rejectMessage {
            let msg = ChatMessage(sender: .assistant, content: .nonMedicalReject(reject), timestamp: Date())
            withAnimation { messages.append(msg) }
        } else if let result = analysis.result {
            let msg = ChatMessage(sender: .assistant, content: .analysisResult(result), timestamp: Date())
            withAnimation { messages.append(msg) }
        }
    }
}

#Preview {
    AssistantView()
        .environmentObject(AppState.shared)
        .environment(\.layoutDirection, .rightToLeft)
}
