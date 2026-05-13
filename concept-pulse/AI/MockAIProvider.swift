import SwiftUI

// MARK: - Mock AI Provider
// Controlled mock that simulates real AI behaviour:
// symptom triage, image safety, emergency detection, specialty matching.
// Replace with OpenAIProvider/ClaudeProvider when API keys are available.

final class MockAIProvider: AIProviderProtocol {

    // MARK: Text Response
    func generateMedicalResponse(query: String, language: AppLanguage) async -> AIResponse {
        try? await Task.sleep(nanoseconds: 1_400_000_000)
        let lower = query.lowercased()

        if EmergencyDetector.isEmergency(query) {
            return AIResponse(
                text: EmergencyDetector.emergencyMessage(language),
                specialty: nil,
                suggestedDoctors: [],
                isEmergency: true,
                analysisCard: nil
            )
        }

        // Symptom → specialty mapping
        for rule in TriageRules.rules {
            let hit = rule.arKeywords.contains { lower.contains($0) }
                   || rule.ruKeywords.contains { lower.contains($0.lowercased()) }
            if hit {
                let triage = buildTriage(rule: rule, language: language)
                let card = buildAnalysisCard(rule: rule, language: language)
                return AIResponse(
                    text: triage,
                    specialty: rule.specialtyKey,
                    suggestedDoctors: matchedDoctors(specialtyKey: rule.specialtyKey),
                    isEmergency: false,
                    analysisCard: card
                )
            }
        }

        // General response
        return AIResponse(
            text: generalResponse(for: query, language: language),
            specialty: nil,
            suggestedDoctors: [],
            isEmergency: false,
            analysisCard: nil
        )
    }

    // MARK: Image Analysis
    func analyzeImage(_ image: UIImage, language: AppLanguage) async -> AIImageAnalysis {
        try? await Task.sleep(nanoseconds: 2_200_000_000)
        // Mock: classify as medical ~70% of the time for demo realism
        // In production the Edge Function calls vision API and returns category
        let isMedical = arc4random_uniform(10) < 7  // 70% medical in mock
        if !isMedical {
            return AIImageAnalysis(
                category: .nonMedical,
                result: nil,
                rejectMessage: ImageClassifier.nonMedicalMessage(language)
            )
        }
        return AIImageAnalysis(
            category: .bloodTest,
            result: buildImageAnalysisCard(language: language),
            rejectMessage: nil
        )
    }

    // MARK: Triage
    func triageSymptoms(_ symptoms: String, language: AppLanguage) async -> TriageResult {
        try? await Task.sleep(nanoseconds: 1_200_000_000)
        let lower = symptoms.lowercased()
        for rule in TriageRules.rules {
            let hit = rule.arKeywords.contains { lower.contains($0) }
                   || rule.ruKeywords.contains { lower.contains($0.lowercased()) }
            if hit {
                return TriageResult(
                    specialty: language == .arabic ? rule.specialtyAr : rule.specialtyRu,
                    specialtyKey: rule.specialtyKey,
                    urgency: rule.urgency,
                    reasoning: language == .arabic ? rule.reasoningAr : rule.reasoningRu,
                    suggestedDoctors: matchedDoctors(specialtyKey: rule.specialtyKey),
                    disclaimer: Loc.aiDisclaimer
                )
            }
        }
        return TriageResult(
            specialty: language == .arabic ? "طب عام" : "Терапевт",
            specialtyKey: "باطنة",
            urgency: .routine,
            reasoning: language == .arabic
                ? "لم أتمكن من تحديد تخصص محدد. أنصح بزيارة طبيب عام أولاً."
                : "Не удалось определить конкретную специальность. Рекомендую начать с терапевта.",
            suggestedDoctors: matchedDoctors(specialtyKey: "باطنة"),
            disclaimer: Loc.aiDisclaimer
        )
    }

    // MARK: - Private Helpers

    private func matchedDoctors(specialtyKey: String) -> [DoctorDetail] {
        SampleData.doctorDetails.filter { $0.specialtyKey == specialtyKey }
    }

    private func buildTriage(rule: TriageRule, language: AppLanguage) -> String {
        let lang = language
        let specialty = lang == .arabic ? rule.specialtyAr : rule.specialtyRu
        let reasoning = lang == .arabic ? rule.reasoningAr : rule.reasoningRu
        let book = lang == .arabic ? "هل تريد حجز موعد مع طبيب \(specialty)؟" : "Хотите записаться к \(specialty.lowercased())?"
        let disclaimer = Loc.aiDisclaimer
        return "\(reasoning)\n\n🏥 \(book)\n\n⚠️ \(disclaimer)"
    }

    private func buildAnalysisCard(rule: TriageRule, language: AppLanguage) -> AnalysisResult {
        let specialty = language == .arabic ? rule.specialtyAr : rule.specialtyRu
        let title = language == .arabic ? "تحليل الأعراض" : "Анализ симптомов"
        let summary = language == .arabic ? rule.reasoningAr : rule.reasoningRu
        return AnalysisResult(
            title: title,
            summary: summary,
            tags: [
                AnalysisTag(label: specialty, color: Color(red: 0.40, green: 0.70, blue: 0.85)),
                urgencyTag(rule.urgency, language: language)
            ],
            disclaimer: Loc.aiDisclaimer
        )
    }

    private func urgencyTag(_ urgency: TriageUrgency, language: AppLanguage) -> AnalysisTag {
        switch urgency {
        case .emergency:
            return AnalysisTag(label: language == .arabic ? "طارئ" : "Срочно", color: .red)
        case .urgent:
            return AnalysisTag(label: language == .arabic ? "عاجل" : "Требует внимания", color: Color(red: 0.95, green: 0.70, blue: 0.40))
        case .routine:
            return AnalysisTag(label: language == .arabic ? "روتيني" : "Плановый", color: Color(red: 0.30, green: 0.72, blue: 0.55))
        }
    }

    private func buildImageAnalysisCard(language: AppLanguage) -> AnalysisResult {
        let isAr = language == .arabic
        return AnalysisResult(
            title: isAr ? "تحليل الصورة الطبية" : "Анализ медицинского снимка",
            summary: isAr
                ? "تمت معالجة الصورة. يظهر انخفاض طفيف في الهيموجلوبين (١١.٢ g/dL). يُنصح بمراجعة طبيب باطنة لإجراء تحليل دم شامل."
                : "Изображение обработано. Наблюдается небольшое снижение гемоглобина (11.2 g/dL). Рекомендуется обратиться к терапевту для полного анализа крови.",
            tags: [
                AnalysisTag(label: isAr ? "تحليل دم" : "Анализ крови", color: Color(red: 0.90, green: 0.36, blue: 0.42)),
                AnalysisTag(label: isAr ? "يحتاج متابعة" : "Требует контроля", color: Color(red: 0.95, green: 0.70, blue: 0.40))
            ],
            disclaimer: Loc.aiDisclaimer
        )
    }

    private func generalResponse(for query: String, language: AppLanguage) -> String {
        let isAr = language == .arabic
        if isAr {
            return "شكراً على سؤالك! 🤔\n\nلضمان حصولك على معلومات موثوقة بخصوص **«\(query)»**، أنصحك بـ:\n\n• استشارة طبيب متخصص\n• زيارة موقع المنظمة الصحية الموثوق\n\nيمكنني مساعدتك في وصف أعراضك بالتفصيل للحصول على اقتراح التخصص المناسب. 💙"
        } else {
            return "Спасибо за вопрос! 🤔\n\nДля получения достоверной информации по теме **«\(query)»** рекомендую:\n\n• Проконсультироваться со специалистом\n• Обратиться к авторитетным медицинским источникам\n\nОпишите ваши симптомы подробнее — я помогу определить подходящего врача. 💙"
        }
    }
}

// MARK: - Triage Rules

struct TriageRule {
    let arKeywords: [String]
    let ruKeywords: [String]
    let specialtyKey: String
    let specialtyAr: String
    let specialtyRu: String
    let urgency: TriageUrgency
    let reasoningAr: String
    let reasoningRu: String
}

enum TriageRules {
    static let rules: [TriageRule] = [
        TriageRule(
            arKeywords: ["ألم صدر", "خفقان", "ضغط دم", "قلب", "ضربات القلب"],
            ruKeywords: ["боль в сердце", "сердцебиение", "давление", "кардио", "сердце"],
            specialtyKey: "قلب",
            specialtyAr: "طبيب قلب",
            specialtyRu: "кардиологу",
            urgency: .urgent,
            reasoningAr: "الأعراض التي ذكرتها قد تشير إلى مشكلة في القلب أو الأوعية الدموية.\n\nأنصحك بمراجعة **طبيب قلب** لتقييم دقيق. إذا كان الألم شديداً أو مصحوباً بضيق تنفس، اطلب الإسعاف فوراً.",
            reasoningRu: "Симптомы могут указывать на проблемы с сердцем или сосудами.\n\nРекомендуется обратиться к **кардиологу** для точной оценки. При сильной боли или одышке — вызовите скорую немедленно."
        ),
        TriageRule(
            arKeywords: ["سكر", "غلوكوز", "غدة", "درقية", "وزن", "إرهاق شديد"],
            ruKeywords: ["сахар", "глюкоза", "щитовидная", "диабет", "гормоны"],
            specialtyKey: "باطنة",
            specialtyAr: "طبيب باطنة",
            specialtyRu: "эндокринологу",
            urgency: .routine,
            reasoningAr: "قد تكون الأعراض مرتبطة بمستوى السكر في الدم أو الغدة الدرقية.\n\nأنصح بمراجعة **طبيب باطنة ومتخصص في السكري** لإجراء التحاليل اللازمة.",
            reasoningRu: "Симптомы могут быть связаны с уровнем сахара в крови или щитовидной железой.\n\nРекомендуется обратиться к **эндокринологу** для сдачи анализов."
        ),
        TriageRule(
            arKeywords: ["صداع", "دوخة", "دوار", "رأس", "ذاكرة"],
            ruKeywords: ["головная боль", "головокружение", "голова", "память"],
            specialtyKey: "باطنة",
            specialtyAr: "طبيب باطنة",
            specialtyRu: "терапевту",
            urgency: .routine,
            reasoningAr: "الصداع والدوخة قد يكون لهما أسباب متعددة مثل الضغط أو الإجهاد أو انخفاض السكر.\n\nأبدأ بمراجعة **طبيب عام أو باطنة** لتحديد السبب.",
            reasoningRu: "Головная боль и головокружение могут иметь разные причины: давление, усталость, низкий сахар.\n\nНачните с визита к **терапевту** для определения причины."
        ),
        TriageRule(
            arKeywords: ["جلد", "حبوب", "حكة", "طفح", "بشرة", "شعر"],
            ruKeywords: ["кожа", "прыщи", "зуд", "сыпь", "дерматит", "волосы"],
            specialtyKey: "جلدية",
            specialtyAr: "طبيب جلدية",
            specialtyRu: "дерматологу",
            urgency: .routine,
            reasoningAr: "الأعراض الجلدية التي ذكرتها تحتاج إلى فحص متخصص.\n\nأنصح بمراجعة **طبيب جلدية** لتشخيص الحالة بدقة وتحديد العلاج المناسب.",
            reasoningRu: "Описанные кожные симптомы требуют специализированного осмотра.\n\nРекомендую обратиться к **дерматологу** для точной диагностики и лечения."
        ),
        TriageRule(
            arKeywords: ["طفل", "رضيع", "حمى أطفال", "تطعيم", "أطفال"],
            ruKeywords: ["ребёнок", "младенец", "дети", "прививка", "педиатр"],
            specialtyKey: "أطفال",
            specialtyAr: "طبيب أطفال",
            specialtyRu: "педиатру",
            urgency: .routine,
            reasoningAr: "ما يخص صحة الأطفال يستدعي متابعة متخصصة.\n\nأنصح بمراجعة **طبيب أطفال** لتقييم الحالة بشكل دقيق.",
            reasoningRu: "Вопросы здоровья детей требуют специализированного подхода.\n\nРекомендую обратиться к **педиатру** для точной оценки."
        ),
        TriageRule(
            arKeywords: ["قلق", "اكتئاب", "توتر", "نوم", "نفسي", "حزن"],
            ruKeywords: ["тревога", "депрессия", "стресс", "сон", "психолог", "грусть"],
            specialtyKey: "نفسي",
            specialtyAr: "طبيب نفسي",
            specialtyRu: "психиатру",
            urgency: .routine,
            reasoningAr: "الأعراض النفسية التي تصفها تستحق الاهتمام والرعاية.\n\nأنصح بمراجعة **طبيب نفسي أو معالج نفسي** — طلب المساعدة خطوة شجاعة. 💙",
            reasoningRu: "Описанные психологические симптомы заслуживают внимания и заботы.\n\nРекомендую обратиться к **психиатру или психотерапевту** — просить о помощи — это смелый шаг. 💙"
        ),
        TriageRule(
            arKeywords: ["أسنان", "لثة", "ضرس", "ألم أسنان", "تقويم"],
            ruKeywords: ["зубы", "дёсны", "зуб", "боль в зубах", "брекеты"],
            specialtyKey: "أسنان",
            specialtyAr: "طبيب أسنان",
            specialtyRu: "стоматологу",
            urgency: .routine,
            reasoningAr: "ألم الأسنان أو مشاكل اللثة يحتاج إلى تقييم متخصص.\n\nأنصح بمراجعة **طبيب أسنان** في أقرب وقت.",
            reasoningRu: "Боль в зубах или проблемы с дёснами требуют специализированного осмотра.\n\nРекомендую обратиться к **стоматологу** как можно скорее."
        )
    ]
}
