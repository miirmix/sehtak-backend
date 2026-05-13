import SwiftUI
import PhotosUI

struct AssistantView: View {
    @State private var messages: [ChatMessage] = SampleConversation.messages
    @State private var inputText = ""
    @State private var isTyping = false
    @State private var showImagePicker = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var showQuickPrompts = true
    @FocusState private var inputFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                AppTheme.bg.ignoresSafeArea()
                VStack(spacing: 0) {
                    chatList
                    inputBar
                }
            }
            .navigationTitle(L.assistant)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
        }
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
                        ChatBubble(message: msg)
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
            Text("ابدأ بسؤال سريع")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
            let columns = [GridItem(.flexible()), GridItem(.flexible())]
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(AIPrompts.quickPrompts) { prompt in
                    QuickPromptChip(prompt: prompt) {
                        send(prompt.textAr)
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
                TextField("اكتب سؤالك الصحي...", text: $inputText, axis: .vertical)
                    .font(.body)
                    .lineLimit(1...4)
                    .focused($inputFocused)
                    .multilineTextAlignment(.trailing)
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
                withAnimation {
                    messages = SampleConversation.messages
                    showQuickPrompts = true
                }
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.primary)
            }
        }
        ToolbarItem(placement: .topBarLeading) {
            HStack(spacing: 6) {
                Circle()
                    .fill(AppTheme.success)
                    .frame(width: 8, height: 8)
                Text("متصل")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.success)
            }
        }
    }

    // MARK: - Actions
    private func sendCurrent() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        inputText = ""
        send(text)
    }

    private func send(_ text: String) {
        withAnimation { showQuickPrompts = false }
        let userMsg = ChatMessage(sender: .user, content: .text(text), timestamp: Date())
        messages.append(userMsg)
        isTyping = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            isTyping = false
            let reply = SampleConversation.aiReply(for: text)
            let aiMsg = ChatMessage(sender: .assistant, content: .text(reply), timestamp: Date())
            withAnimation { messages.append(aiMsg) }
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
        let userMsg = ChatMessage(sender: .user, content: .image(img, caption: "صورة طبية للتحليل"), timestamp: Date())
        messages.append(userMsg)
        isTyping = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            isTyping = false
            let result = SampleConversation.sampleAnalysis
            let aiMsg = ChatMessage(sender: .assistant, content: .analysisResult(result), timestamp: Date())
            withAnimation { messages.append(aiMsg) }
        }
    }
}

#Preview {
    AssistantView().environment(\.layoutDirection, .rightToLeft)
}
