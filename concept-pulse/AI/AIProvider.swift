import SwiftUI

// MARK: - AI Provider Abstraction
// Production-ready interface. Connect OpenAI/Claude by implementing AIProviderProtocol
// and injecting via AIProviderFactory.make(). API keys must NEVER be stored in app —
// route all real calls through a Supabase Edge Function.

protocol AIProviderProtocol {
    func generateMedicalResponse(query: String, language: AppLanguage) async -> AIResponse
    func analyzeImage(_ image: UIImage, language: AppLanguage) async -> AIImageAnalysis
    func triageSymptoms(_ symptoms: String, language: AppLanguage) async -> TriageResult
}

// MARK: - Response Types

struct AIResponse {
    let text: String
    let specialty: String?          // matched specialty key
    let suggestedDoctors: [DoctorDetail]
    let isEmergency: Bool
    let analysisCard: AnalysisResult?
}

struct AIImageAnalysis {
    enum ImageCategory {
        case medical, ecg, bloodTest, prescription, labReport, nonMedical, unknown
    }
    let category: ImageCategory
    let result: AnalysisResult?
    let rejectMessage: String?      // set when nonMedical
}

struct TriageResult {
    let specialty: String           // display name
    let specialtyKey: String
    let urgency: TriageUrgency
    let reasoning: String
    let suggestedDoctors: [DoctorDetail]
    let disclaimer: String
}

enum TriageUrgency {
    case emergency, urgent, routine
}

// MARK: - Factory

enum AIProviderFactory {
    /// OpenAIProvider routes all calls through the Supabase Edge Function.
    /// Fall back to MockAIProvider() locally if the Edge Function is unavailable.
    static func make() -> AIProviderProtocol {
        return OpenAIProvider()
    }
}

// MARK: - Emergency Keywords

enum EmergencyDetector {
    static let arabicKeywords = [
        "ألم صدري", "ضيق تنفس", "شلل", "فقدان الوعي", "نزيف شديد",
        "ضربة شمس", "انتحار", "إغماء", "جلطة", "احتشاء"
    ]
    static let russianKeywords = [
        "боль в груди", "одышка", "паралич", "потеря сознания", "сильное кровотечение",
        "инсульт", "суицид", "обморок", "инфаркт", "тромб"
    ]

    static func isEmergency(_ text: String) -> Bool {
        let lower = text.lowercased()
        return (arabicKeywords + russianKeywords).contains { lower.contains($0.lowercased()) }
    }

    static func emergencyMessage(_ lang: AppLanguage) -> String {
        lang == .arabic
        ? "⚠️ قد تكون هذه الأعراض طارئة. يُنصح بالتواصل مع الإسعاف (٩١١) أو زيارة الطوارئ فوراً."
        : "⚠️ Эти симптомы могут быть неотложными. Срочно позвоните в скорую помощь (103) или обратитесь в отделение неотложной помощи."
    }
}

// MARK: - Image Classifier (keyword-based mock)

enum ImageClassifier {
    static func nonMedicalMessage(_ lang: AppLanguage) -> String {
        lang == .arabic
        ? "الصورة المرفقة لا تبدو صورة طبية أو نتيجة فحص. يمكنني مساعدتك فقط في تحليل الصور الطبية أو نتائج التحاليل أو وصف الأعراض."
        : "Загруженное изображение не похоже на медицинское изображение или результат обследования. Я могу помочь только с медицинскими изображениями, анализами или описанием симптомов."
    }
}
