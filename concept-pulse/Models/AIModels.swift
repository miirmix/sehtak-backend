import SwiftUI
import PhotosUI

// MARK: - Chat Models

enum MessageSender {
    case user, assistant
}

enum MessageContent {
    case text(String)
    case image(UIImage, caption: String?)
    case analysisResult(AnalysisResult)
    case triageResult(TriageResult)
    case emergencyAlert(String)
    case nonMedicalReject(String)
    case doctorSuggestions([DoctorDetail])
}

struct AnalysisResult {
    let title: String
    let summary: String
    let tags: [AnalysisTag]
    let disclaimer: String
}

struct AnalysisTag: Identifiable {
    let id = UUID()
    let label: String
    let color: Color
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let sender: MessageSender
    let content: MessageContent
    let timestamp: Date
}

// MARK: - Quick Prompts

struct QuickPrompt: Identifiable {
    let id = UUID()
    let icon: String
    let textAr: String
    let textRu: String
    let color: Color

    var displayText: String { Loc.lang == .arabic ? textAr : textRu }
}

enum AIPrompts {
    static let quickPrompts: [QuickPrompt] = [
        .init(icon: "heart.fill",         textAr: "أعاني من ألم في الصدر",   textRu: "Боль в груди", color: Color(red: 0.90, green: 0.40, blue: 0.45)),
        .init(icon: "drop.fill",          textAr: "ارتفاع السكر في الدم",    textRu: "Высокий сахар", color: Color(red: 0.40, green: 0.70, blue: 0.85)),
        .init(icon: "hand.raised.fill",   textAr: "طفح جلدي وحكة",           textRu: "Сыпь и зуд", color: Color(red: 0.75, green: 0.55, blue: 0.85)),
        .init(icon: "brain.head.profile", textAr: "أعاني من قلق وتوتر",     textRu: "Тревога и стресс", color: Color(red: 0.85, green: 0.55, blue: 0.70)),
        .init(icon: "cross.case.fill",    textAr: "متى أراجع الطوارئ؟",     textRu: "Когда идти в скорую?", color: Color(red: 0.95, green: 0.36, blue: 0.42)),
        .init(icon: "figure.walk",        textAr: "إرهاق وانخفاض الهيموجلوبين", textRu: "Усталость, низкий гемоглобин", color: Color(red: 0.50, green: 0.75, blue: 0.60))
    ]
}

// MARK: - Sample Conversation (welcome message only)

enum SampleConversation {
    static func welcomeMessages(language: AppLanguage) -> [ChatMessage] {
        let text = language == .arabic
            ? "مرحباً! أنا مساعدك الطبي الذكي 👋\n\nيمكنني مساعدتك في:\n• تحليل الأعراض واقتراح التخصص المناسب\n• تحليل الصور الطبية ونتائج الفحوصات\n• الإجابة على أسئلتك الصحية\n\n⚠️ جميع مشوراتي لأغراض توعوية فقط ولا تُغني عن استشارة طبيبك."
            : "Привет! Я ваш медицинский ИИ-ассистент 👋\n\nЯ могу помочь вам:\n• Анализировать симптомы и подобрать специалиста\n• Анализировать медицинские снимки и результаты анализов\n• Отвечать на вопросы о здоровье\n\n⚠️ Все мои рекомендации носят информационный характер и не заменяют консультацию врача."
        return [ChatMessage(sender: .assistant, content: .text(text), timestamp: Date().addingTimeInterval(-300))]
    }
}
