import SwiftUI

// MARK: - GigaChat Provider
// All calls go through the Supabase Edge Function — the GigaChat key never leaves the server.
// Requires a valid Supabase anon JWT in the Authorization header (Edge Function has verify_jwt=true).

final class GigaChatProvider: AIProviderProtocol {

    // MARK: Text Query
    func generateMedicalResponse(query: String, language: AppLanguage) async -> AIResponse {
        // Emergency check runs locally first — no network round-trip for safety
        if EmergencyDetector.isEmergency(query) {
            return AIResponse(
                text: EmergencyDetector.emergencyMessage(language),
                specialty: nil,
                suggestedDoctors: [],
                isEmergency: true,
                analysisCard: nil
            )
        }

        let body: [String: Any] = [
            "action": "text_query",
            "query": query,
            "language": language.rawValue
        ]
        guard let dto = try? await callProxy(body: body) else {
            return fallbackResponse(language: language)
        }

        let isEmergency     = dto["isEmergency"]      as? Bool   ?? false
        let urgencyRaw      = dto["urgency"]           as? String ?? "routine"
        let specialtyKey    = dto["specialtyKey"]      as? String
        let text            = dto["responseText"]      as? String ?? ""
        let disclaimer      = dto["disclaimer"]        as? String ?? Loc.aiDisclaimer
        let specialtyDisplay = dto["specialtyDisplay"] as? String

        if isEmergency {
            return AIResponse(text: EmergencyDetector.emergencyMessage(language),
                              specialty: nil, suggestedDoctors: [],
                              isEmergency: true, analysisCard: nil)
        }

        let urgency  = parseUrgency(urgencyRaw)
        let doctors  = specialtyKey.map { matchDoctors(specialtyKey: $0) } ?? []
        let cardTags = buildTags(urgency: urgency, specialty: specialtyDisplay, language: language)
        let card: AnalysisResult? = specialtyKey != nil ? AnalysisResult(
            title: language == .arabic ? "تحليل الأعراض" : "Анализ симптомов",
            summary: text,
            tags: cardTags,
            disclaimer: disclaimer
        ) : nil

        return AIResponse(
            text: text,
            specialty: specialtyKey,
            suggestedDoctors: doctors,
            isEmergency: false,
            analysisCard: card
        )
    }

    // MARK: Image Analysis
    func analyzeImage(_ image: UIImage, language: AppLanguage) async -> AIImageAnalysis {
        guard let jpeg = image.jpegData(compressionQuality: 0.6) else {
            return nonMedicalReject(language: language)
        }
        let base64 = jpeg.base64EncodedString()
        let body: [String: Any] = [
            "action": "image_analysis",
            "imageBase64": base64,
            "mimeType": "image/jpeg",
            "language": language.rawValue
        ]
        guard let dto = try? await callProxy(body: body) else {
            return nonMedicalReject(language: language)
        }

        // If backend signals image vision is unsupported
        if dto["visionUnsupported"] as? Bool == true {
            let msg = language == .arabic
                ? "تحليل الصور غير متاح حالياً. يمكنك وصف أعراضك نصياً وسأساعدك."
                : "Анализ изображений временно недоступен. Опишите симптомы текстом, и я помогу."
            return AIImageAnalysis(category: .unknown, result: nil, rejectMessage: msg)
        }

        let isMedical  = dto["isMedical"]  as? Bool   ?? false
        let category   = dto["category"]   as? String ?? "unknown"
        let title      = dto["title"]      as? String ?? (language == .arabic ? "تحليل الصورة" : "Анализ снимка")
        let summary    = dto["summary"]    as? String ?? ""
        let findings   = dto["findings"]   as? [String] ?? []
        let specialty  = dto["recommendedSpecialty"] as? String
        let disclaimer = dto["disclaimer"] as? String ?? Loc.aiDisclaimer

        if !isMedical || category == "non_medical" || category == "unknown" {
            return nonMedicalReject(language: language)
        }

        let allText = findings.isEmpty
            ? summary
            : summary + "\n\n" + findings.map { "• \($0)" }.joined(separator: "\n")
        let tags   = buildImageTags(category: category, specialty: specialty)
        let result = AnalysisResult(title: title, summary: allText, tags: tags, disclaimer: disclaimer)
        return AIImageAnalysis(category: mapCategory(category), result: result, rejectMessage: nil)
    }

    // MARK: Triage
    func triageSymptoms(_ symptoms: String, language: AppLanguage) async -> TriageResult {
        let response = await generateMedicalResponse(query: symptoms, language: language)
        let specialty = response.specialty ?? (language == .arabic ? "طب عام" : "Терапевт")
        return TriageResult(
            specialty: specialty,
            specialtyKey: response.specialty ?? "باطنة",
            urgency: .routine,
            reasoning: response.text,
            suggestedDoctors: response.suggestedDoctors,
            disclaimer: Loc.aiDisclaimer
        )
    }

    // MARK: - Private Helpers

    private func callProxy(body: [String: Any]) async throws -> [String: Any] {
        guard let url = URL(string: SupabaseConfig.aiProxyURL) else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.timeoutInterval = 30
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let json else { throw URLError(.cannotParseResponse) }
        if json["error"] != nil { throw URLError(.badServerResponse) }
        return json
    }

    private func matchDoctors(specialtyKey: String) -> [DoctorDetail] {
        SampleData.doctorDetails.filter { $0.specialtyKey == specialtyKey }
    }

    private func parseUrgency(_ raw: String) -> TriageUrgency {
        switch raw {
        case "emergency": return .emergency
        case "urgent":    return .urgent
        default:          return .routine
        }
    }

    private func buildTags(urgency: TriageUrgency, specialty: String?, language: AppLanguage) -> [AnalysisTag] {
        var tags: [AnalysisTag] = []
        if let s = specialty {
            tags.append(AnalysisTag(label: s, color: Color(red: 0.40, green: 0.70, blue: 0.85)))
        }
        switch urgency {
        case .emergency:
            tags.append(AnalysisTag(label: language == .arabic ? "طارئ 🔴" : "Срочно 🔴", color: .red))
        case .urgent:
            tags.append(AnalysisTag(label: language == .arabic ? "عاجل 🟡" : "Неотложно 🟡", color: .orange))
        case .routine:
            tags.append(AnalysisTag(
                label: language == .arabic ? "روتيني 🟢" : "Плановый 🟢",
                color: Color(red: 0.30, green: 0.72, blue: 0.55)
            ))
        }
        return tags
    }

    private func buildImageTags(category: String, specialty: String?) -> [AnalysisTag] {
        var tags: [AnalysisTag] = []
        let catColor: Color = {
            switch category {
            case "blood_test":   return Color(red: 0.90, green: 0.36, blue: 0.42)
            case "ecg":          return Color(red: 0.40, green: 0.70, blue: 0.85)
            case "prescription": return Color(red: 0.50, green: 0.75, blue: 0.60)
            default:             return Color(red: 0.75, green: 0.55, blue: 0.85)
            }
        }()
        tags.append(AnalysisTag(label: localizedCategory(category), color: catColor))
        if let s = specialty {
            tags.append(AnalysisTag(label: s, color: Color(red: 0.95, green: 0.70, blue: 0.40)))
        }
        return tags
    }

    private func localizedCategory(_ cat: String) -> String {
        let isAr = Loc.lang == .arabic
        switch cat {
        case "ecg":          return isAr ? "رسم قلب" : "ЭКГ"
        case "blood_test":   return isAr ? "تحليل دم" : "Анализ крови"
        case "prescription": return isAr ? "وصفة طبية" : "Рецепт"
        case "lab_report":   return isAr ? "تقرير مختبر" : "Анализы"
        default:             return isAr ? "صورة طبية" : "Медснимок"
        }
    }

    private func mapCategory(_ raw: String) -> AIImageAnalysis.ImageCategory {
        switch raw {
        case "ecg":          return .ecg
        case "blood_test":   return .bloodTest
        case "prescription": return .prescription
        case "lab_report":   return .labReport
        case "non_medical":  return .nonMedical
        default:             return .medical
        }
    }

    private func nonMedicalReject(language: AppLanguage) -> AIImageAnalysis {
        AIImageAnalysis(category: .nonMedical, result: nil,
                        rejectMessage: ImageClassifier.nonMedicalMessage(language))
    }

    private func fallbackResponse(language: AppLanguage) -> AIResponse {
        let text = language == .arabic
            ? "عذراً، حدث خطأ في الاتصال. يرجى المحاولة مجدداً أو التواصل مع الدعم."
            : "Произошла ошибка соединения. Пожалуйста, повторите попытку."
        return AIResponse(text: text, specialty: nil, suggestedDoctors: [],
                          isEmergency: false, analysisCard: nil)
    }
}
