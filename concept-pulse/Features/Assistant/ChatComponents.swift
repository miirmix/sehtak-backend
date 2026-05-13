import SwiftUI

// MARK: - Chat Bubble

struct ChatBubble: View {
    let message: ChatMessage
    var onBookDoctor: ((DoctorDetail) -> Void)?

    var isUser: Bool { message.sender == .user }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isUser { Spacer(minLength: 50) }
            if !isUser { assistantAvatar }
            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                bubbleContent
                timestampLabel
            }
            if !isUser { Spacer(minLength: 50) }
        }
    }

    @ViewBuilder
    private var bubbleContent: some View {
        switch message.content {
        case .text(let txt):
            TextBubble(text: txt, isUser: isUser)
        case .image(let img, let caption):
            ImageBubble(image: img, caption: caption, isUser: isUser)
        case .analysisResult(let result):
            AnalysisCard(result: result)
        case .triageResult(let triage):
            TriageCard(triage: triage, onBook: onBookDoctor)
        case .emergencyAlert(let msg):
            EmergencyBubble(message: msg)
        case .nonMedicalReject(let msg):
            TextBubble(text: msg, isUser: false)
        case .doctorSuggestions(let doctors):
            DoctorSuggestionsCard(doctors: doctors, onBook: onBookDoctor)
        }
    }

    private var timestampLabel: some View {
        let fmt = DateFormatter()
        fmt.dateFormat = "h:mm a"
        return Text(fmt.string(from: message.timestamp))
            .font(.system(size: 10))
            .foregroundStyle(AppTheme.textSecondary)
            .padding(.horizontal, 4)
    }

    private var assistantAvatar: some View {
        ZStack {
            Circle()
                .fill(AppTheme.gradient)
                .frame(width: 32, height: 32)
            Image(systemName: "sparkles")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Text Bubble

struct TextBubble: View {
    let text: String
    let isUser: Bool

    var body: some View {
        Text(LocalizedStringKey(text))
            .font(.callout)
            .foregroundStyle(isUser ? .white : AppTheme.textPrimary)
            .multilineTextAlignment(isUser ? .trailing : .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isUser ? AppTheme.primary : AppTheme.card)
            .clipShape(BubbleShape(isUser: isUser))
            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Emergency Bubble

struct EmergencyBubble: View {
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
            Text(message)
                .font(.callout.weight(.semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
        }
        .padding(14)
        .background(Color.red.gradient)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.red.opacity(0.3), radius: 10, x: 0, y: 4)
        .frame(maxWidth: 300)
    }
}

// MARK: - Image Bubble

struct ImageBubble: View {
    let image: UIImage
    let caption: String?
    let isUser: Bool

    var body: some View {
        VStack(alignment: isUser ? .trailing : .leading, spacing: 6) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 200, height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AppTheme.primarySoft, lineWidth: 1)
                )
            if let caption {
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
    }
}

// MARK: - Analysis Result Card

struct AnalysisCard: View {
    let result: AnalysisResult

    var body: some View {
        VStack(alignment: .trailing, spacing: 12) {
            HStack(spacing: 8) {
                Spacer()
                Text(result.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)
                ZStack {
                    Circle().fill(AppTheme.primarySoft).frame(width: 32, height: 32)
                    Image(systemName: "waveform.and.mic")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.primary)
                }
            }
            Divider()
            Text(LocalizedStringKey(result.summary))
                .font(.callout)
                .foregroundStyle(AppTheme.textPrimary)
                .multilineTextAlignment(.trailing)
            HStack(spacing: 6) {
                Spacer()
                ForEach(result.tags) { tag in
                    Text(tag.label)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(tag.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(tag.color.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
            DisclaimerRow(text: result.disclaimer)
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.primarySoft, lineWidth: 1.5)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        .frame(maxWidth: 300)
    }
}

// MARK: - Triage Card

struct TriageCard: View {
    let triage: TriageResult
    var onBook: ((DoctorDetail) -> Void)?

    var body: some View {
        VStack(alignment: .trailing, spacing: 12) {
            headerRow
            Divider()
            Text(triage.reasoning)
                .font(.callout)
                .foregroundStyle(AppTheme.textPrimary)
                .multilineTextAlignment(.trailing)
            specialtyBadge
            if !triage.suggestedDoctors.isEmpty {
                doctorsList
            }
            DisclaimerRow(text: triage.disclaimer)
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.primarySoft, lineWidth: 1.5)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        .frame(maxWidth: 320)
    }

    private var headerRow: some View {
        HStack(spacing: 8) {
            Spacer()
            let title = Loc.lang == .arabic ? "اقتراح التخصص" : "Рекомендация специалиста"
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppTheme.textPrimary)
            ZStack {
                Circle().fill(AppTheme.primarySoft).frame(width: 32, height: 32)
                Image(systemName: "stethoscope")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.primary)
            }
        }
    }

    private var specialtyBadge: some View {
        HStack(spacing: 6) {
            Spacer()
            urgencyLabel
            Text(triage.specialty)
                .font(.footnote.weight(.bold))
                .foregroundStyle(AppTheme.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(AppTheme.primarySoft)
                .clipShape(Capsule())
        }
    }

    @ViewBuilder
    private var urgencyLabel: some View {
        switch triage.urgency {
        case .emergency:
            urgencyChip(Loc.lang == .arabic ? "طارئ 🔴" : "Срочно 🔴", color: .red)
        case .urgent:
            urgencyChip(Loc.lang == .arabic ? "عاجل 🟡" : "Неотложно 🟡", color: .orange)
        case .routine:
            urgencyChip(Loc.lang == .arabic ? "روتيني 🟢" : "Плановый 🟢", color: AppTheme.success)
        }
    }

    private func urgencyChip(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .clipShape(Capsule())
    }

    private var doctorsList: some View {
        VStack(alignment: .trailing, spacing: 8) {
            let label = Loc.lang == .arabic ? "أطباء مقترحون" : "Рекомендуемые врачи"
            Text(label)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
            ForEach(triage.suggestedDoctors.prefix(2)) { doc in
                MiniDoctorRow(doctor: doc) { onBook?(doc) }
            }
        }
    }
}

// MARK: - Doctor Suggestions Card

struct DoctorSuggestionsCard: View {
    let doctors: [DoctorDetail]
    var onBook: ((DoctorDetail) -> Void)?

    var body: some View {
        VStack(alignment: .trailing, spacing: 10) {
            let title = Loc.lang == .arabic ? "أطباء مقترحون لك 🏥" : "Рекомендуемые врачи 🏥"
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .trailing)
            ForEach(doctors.prefix(3)) { doc in
                MiniDoctorRow(doctor: doc) { onBook?(doc) }
            }
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.primarySoft, lineWidth: 1.5)
        )
        .frame(maxWidth: 320)
    }
}

// MARK: - Mini Doctor Row

struct MiniDoctorRow: View {
    let doctor: DoctorDetail
    let onBook: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            let bookLabel = Loc.lang == .arabic ? "احجز" : "Записаться"
            Button(action: onBook) {
                Text(bookLabel)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AppTheme.primary)
                    .clipShape(Capsule())
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(doctor.displayName)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(doctor.displaySpecialty)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Circle()
                .fill(doctor.avatarColor)
                .frame(width: 36, height: 36)
                .overlay(
                    Text(doctor.initials)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                )
        }
        .padding(10)
        .background(AppTheme.bg)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Disclaimer Row

struct DisclaimerRow: View {
    let text: String
    var body: some View {
        HStack(spacing: 6) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(AppTheme.warning)
            Text(text)
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.trailing)
        }
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    @State private var phase = 0

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ZStack {
                Circle().fill(AppTheme.gradient).frame(width: 32, height: 32)
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
            }
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(AppTheme.primary)
                        .frame(width: 7, height: 7)
                        .scaleEffect(phase == i ? 1.4 : 0.8)
                        .animation(
                            .easeInOut(duration: 0.4).repeatForever().delay(Double(i) * 0.15),
                            value: phase
                        )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(AppTheme.card)
            .clipShape(BubbleShape(isUser: false))
            Spacer(minLength: 50)
        }
        .onAppear {
            withAnimation { phase = 1 }
            Timer.scheduledTimer(withTimeInterval: 0.45, repeats: true) { _ in
                withAnimation { phase = (phase + 1) % 3 }
            }
        }
    }
}

// MARK: - Quick Prompt Chip

struct QuickPromptChip: View {
    let prompt: QuickPrompt
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Spacer()
                Text(prompt.displayText)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(AppTheme.textPrimary)
                    .multilineTextAlignment(.trailing)
                Image(systemName: prompt.icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(prompt.color)
                    .frame(width: 28, height: 28)
                    .background(prompt.color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Bubble Shape

struct BubbleShape: Shape {
    let isUser: Bool

    func path(in rect: CGRect) -> Path {
        let r: CGFloat = 18
        let tailR: CGFloat = 5
        var path = Path()

        if isUser {
            path.addRoundedRect(in: CGRect(x: rect.minX, y: rect.minY,
                                           width: rect.width - tailR,
                                           height: rect.height),
                                cornerSize: CGSize(width: r, height: r))
            path.move(to: CGPoint(x: rect.maxX - tailR, y: rect.maxY - 16))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - 8))
            path.addLine(to: CGPoint(x: rect.maxX - tailR, y: rect.maxY - 8))
        } else {
            path.addRoundedRect(in: CGRect(x: rect.minX + tailR, y: rect.minY,
                                           width: rect.width - tailR,
                                           height: rect.height),
                                cornerSize: CGSize(width: r, height: r))
            path.move(to: CGPoint(x: rect.minX + tailR, y: rect.maxY - 16))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - 8))
            path.addLine(to: CGPoint(x: rect.minX + tailR, y: rect.maxY - 8))
        }
        return path
    }
}
