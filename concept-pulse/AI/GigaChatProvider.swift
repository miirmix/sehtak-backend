import SwiftUI

// MARK: - GigaChat Provider
// All AI calls go through the FastAPI proxy (backend/).
// The GIGACHAT_AUTH_KEY never leaves the server — the iOS app sends only messages.
// Set GigaChatConfig.proxyBaseURL to your Railway/Render URL before release.

final class GigaChatProvider: AIProviderProtocol {

    // MARK: - Startup Diagnostic
    func runDiagnostic() async {
        NSLog("[GigaChat] Proxy URL: \(GigaChatConfig.proxyBaseURL)")
        NSLog("[GigaChat] Configured: \(GigaChatConfig.isConfigured ? "YES" : "NO — update GigaChatConfig.proxyBaseURL")")
        guard GigaChatConfig.isConfigured else { return }
        await pingHealth()
    }

    private func pingHealth() async {
        guard let url = URL(string: GigaChatConfig.healthEndpoint) else { return }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            let body = String(data: data, encoding: .utf8).map { String($0.prefix(200)) } ?? "?"
            NSLog("[GigaChat] /health → HTTP \(status), body=\(body)")
        } catch {
            NSLog("[GigaChat] /health error: \(error.localizedDescription)")
        }
    }

    // MARK: - Full Backend Test (visible in UI)
    func runFullBackendTest() async -> String {
        guard GigaChatConfig.isConfigured else {
            return """
            ⚠️ Backend not configured yet.

            Steps:
            1. Deploy backend/ to Railway or Render (see backend/DEPLOY.md)
            2. Open concept-pulse/AI/GigaChatConfig.swift
            3. Set proxyBaseURL = "https://your-service.railway.app"
            4. Rebuild the app
            """
        }
        guard let url = URL(string: GigaChatConfig.testEndpoint) else { return "❌ Bad URL" }
        NSLog("[GigaChat] Running backend test: \(GigaChatConfig.testEndpoint)")
        do {
            var req = URLRequest(url: url)
            req.timeoutInterval = 30
            let (data, response) = try await URLSession.shared.data(for: req)
            let httpStatus = (response as? HTTPURLResponse)?.statusCode ?? 0
            NSLog("[GigaChat] /test HTTP \(httpStatus)")
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return "HTTP \(httpStatus)\n\n" + (String(data: data, encoding: .utf8) ?? "no data")
            }
            return formatTestResult(json)
        } catch {
            NSLog("[GigaChat] /test error: \(error.localizedDescription)")
            return "❌ Network error: \(error.localizedDescription)"
        }
    }

    private func formatTestResult(_ j: [String: Any]) -> String {
        var lines: [String] = []
        lines.append("🕐 \(j["timestamp"] as? String ?? "-")")
        lines.append("📦 Cert bundle: \(j["cert_bundle_present"] as? Bool == true ? "✅" : "❌ Missing")")
        lines.append("")
        lines.append("🔑 Auth Key: \(j["has_auth_key"] as? Bool == true ? "✅ Present" : "❌ Missing")")
        if let hint = j["key_hint"] as? String { lines.append("   Hint: \(hint)") }
        lines.append("")
        let oauthOk = j["oauth_ok"] as? Bool ?? false
        lines.append("🔐 OAuth: \(oauthOk ? "✅ OK" : "❌ Failed")")
        if let len = j["token_length"] as? Int { lines.append("   Token length: \(len) chars") }
        if let err = j["oauth_error"] as? String { lines.append("   Error: \(err.prefix(200))") }
        lines.append("")
        let chatOk = j["chat_ok"] as? Bool ?? false
        lines.append("💬 Chat: \(chatOk ? "✅ OK" : "❌ Failed")")
        if let st = j["chat_status"] { lines.append("   Status: \(st)") }
        if let reply = j["chat_reply_preview"] as? String { lines.append("   Reply: \(reply.prefix(150))") }
        if let err = j["chat_error"] as? String { lines.append("   Error: \(err.prefix(200))") }
        return lines.joined(separator: "\n")
    }

    // MARK: - Text Query
    func generateMedicalResponse(query: String, language: AppLanguage) async -> AIResponse {
        if EmergencyDetector.isEmergency(query) {
            return AIResponse(
                text: EmergencyDetector.emergencyMessage(language),
                specialty: nil, suggestedDoctors: [],
                isEmergency: true, analysisCard: nil
            )
        }

        guard GigaChatConfig.isConfigured else {
            return notConfiguredResponse(language: language)
        }

        let systemPrompt = buildSystemPrompt(language: language)
        let messages: [[String: String]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user",   "content": query]
        ]

        do {
            let reply = try await callChat(messages: messages)
            return parseTextReply(reply, query: query, language: language)
        } catch {
            NSLog("[GigaChat] generateMedicalResponse error: \(error.localizedDescription)")
            return fallbackResponse(language: language)
        }
    }

    // MARK: - Image Analysis
    func analyzeImage(_ image: UIImage, language: AppLanguage) async -> AIImageAnalysis {
        guard GigaChatConfig.isConfigured else {
            return nonMedicalReject(language: language)
        }
        guard let jpeg = image.jpegData(compressionQuality: 0.6) else {
            return nonMedicalReject(language: language)
        }
        let base64 = jpeg.base64EncodedString()
        let lang = language == .arabic ? "Arabic" : "Russian"
        let prompt = """
        You are a medical image analyzer. Analyze this medical image. \
        Determine if it is a medical image (ECG, blood test, prescription, lab report, X-ray, MRI, etc.). \
        If not medical, respond: {"isMedical":false,"category":"non_medical"}. \
        If medical, respond JSON: {"isMedical":true,"category":"ecg|blood_test|prescription|lab_report|xray|mri|other","title":"...","summary":"...","findings":["..."],"recommendedSpecialty":"...","disclaimer":"..."}. \
        Respond in \(lang). Image base64: \(base64.prefix(100))...[truncated]
        """

        do {
            let messages: [[String: String]] = [["role": "user", "content": prompt]]
            let reply = try await callChat(messages: messages)
            return parseImageReply(reply, language: language)
        } catch {
            return nonMedicalReject(language: language)
        }
    }

    // MARK: - Triage
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

    // MARK: - Core HTTP Call
    private func callChat(messages: [[String: String]]) async throws -> String {
        guard let url = URL(string: GigaChatConfig.chatEndpoint) else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 45

        let body: [String: Any] = [
            "messages":    messages,
            "model":       "GigaChat",
            "temperature": 0.7,
            "max_tokens":  1024
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        NSLog("[GigaChat] POST \(GigaChatConfig.chatEndpoint)")

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        NSLog("[GigaChat] chat HTTP \(status), data=\(data.count) bytes")

        guard (200...299).contains(status) else {
            NSLog("[GigaChat] non-2xx: \(String(data: data, encoding: .utf8) ?? "?")")
            throw URLError(.badServerResponse)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw URLError(.cannotParseResponse)
        }
        return content
    }

    // MARK: - Response Parsing
    private func parseTextReply(_ reply: String, query: String, language: AppLanguage) -> AIResponse {
        // Try JSON extraction first (model might return structured JSON)
        if let jsonStart = reply.range(of: "{"),
           let jsonEnd = reply.range(of: "}", options: .backwards),
           jsonStart.lowerBound < jsonEnd.upperBound {
            let jsonStr = String(reply[jsonStart.lowerBound...jsonEnd.upperBound])
            if let data = jsonStr.data(using: .utf8),
               let dto = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return buildAIResponse(from: dto, fallbackText: reply, language: language)
            }
        }
        // Plain text fallback
        let doctors  = matchDoctors(specialtyKey: nil)
        let urgency  = detectUrgency(in: reply)
        let tags     = buildTags(urgency: urgency, specialty: nil, language: language)
        let card     = AnalysisResult(
            title: language == .arabic ? "تحليل الأعراض" : "Анализ симптомов",
            summary: reply,
            tags: tags,
            disclaimer: Loc.aiDisclaimer
        )
        return AIResponse(text: reply, specialty: nil, suggestedDoctors: doctors,
                          isEmergency: false, analysisCard: card)
    }

    private func buildAIResponse(from dto: [String: Any], fallbackText: String, language: AppLanguage) -> AIResponse {
        let isEmergency     = dto["isEmergency"]  as? Bool   ?? false
        if isEmergency { return AIResponse(text: EmergencyDetector.emergencyMessage(language),
                                           specialty: nil, suggestedDoctors: [],
                                           isEmergency: true, analysisCard: nil) }
        let urgencyRaw      = dto["urgency"]       as? String ?? "routine"
        let specialtyKey    = dto["specialtyKey"]  as? String
        let text            = dto["responseText"]  as? String ?? fallbackText
        let disclaimer      = dto["disclaimer"]    as? String ?? Loc.aiDisclaimer
        let specialtyDisplay = dto["specialtyDisplay"] as? String
        let urgency         = parseUrgency(urgencyRaw)
        let doctors         = specialtyKey.map { matchDoctors(specialtyKey: $0) } ?? []
        let tags            = buildTags(urgency: urgency, specialty: specialtyDisplay, language: language)
        let card: AnalysisResult? = AnalysisResult(
            title: language == .arabic ? "تحليل الأعراض" : "Анализ симптомов",
            summary: text, tags: tags, disclaimer: disclaimer
        )
        return AIResponse(text: text, specialty: specialtyKey, suggestedDoctors: doctors,
                          isEmergency: false, analysisCard: card)
    }

    private func parseImageReply(_ reply: String, language: AppLanguage) -> AIImageAnalysis {
        guard let jsonStart = reply.range(of: "{"),
              let jsonEnd = reply.range(of: "}", options: .backwards),
              jsonStart.lowerBound < jsonEnd.upperBound,
              let data = String(reply[jsonStart.lowerBound...jsonEnd.upperBound]).data(using: .utf8),
              let dto = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nonMedicalReject(language: language)
        }
        let isMedical = dto["isMedical"]  as? Bool   ?? false
        let category  = dto["category"]   as? String ?? "unknown"
        guard isMedical, category != "non_medical", category != "unknown" else {
            return nonMedicalReject(language: language)
        }
        let title     = dto["title"]    as? String ?? (language == .arabic ? "تحليل الصورة" : "Анализ снимка")
        let summary   = dto["summary"]  as? String ?? ""
        let findings  = dto["findings"] as? [String] ?? []
        let specialty = dto["recommendedSpecialty"] as? String
        let disclaimer = dto["disclaimer"] as? String ?? Loc.aiDisclaimer
        let allText   = findings.isEmpty ? summary : summary + "\n\n" + findings.map { "• \($0)" }.joined(separator: "\n")
        let tags      = buildImageTags(category: category, specialty: specialty)
        let result    = AnalysisResult(title: title, summary: allText, tags: tags, disclaimer: disclaimer)
        return AIImageAnalysis(category: mapCategory(category), result: result, rejectMessage: nil)
    }

    // MARK: - Helpers
    private func buildSystemPrompt(language: AppLanguage) -> String {
        let lang = language == .arabic ? "Arabic" : "Russian"
        return """
        You are a professional medical AI assistant. Always respond in \(lang). \
        Analyze symptoms, suggest the appropriate medical specialty, and assess urgency level. \
        Always recommend consulting a real doctor. \
        Format: JSON with keys: responseText, specialtyKey, specialtyDisplay, urgency (routine/urgent/emergency), \
        isEmergency (bool), disclaimer. \
        CRITICAL: for life-threatening symptoms set isEmergency=true.
        """
    }

    private func matchDoctors(specialtyKey: String?) -> [DoctorDetail] {
        guard let key = specialtyKey else { return [] }
        return SampleData.doctorDetails.filter { $0.specialtyKey == key }
    }

    private func parseUrgency(_ raw: String) -> TriageUrgency {
        switch raw {
        case "emergency": return .emergency
        case "urgent":    return .urgent
        default:          return .routine
        }
    }

    private func detectUrgency(in text: String) -> TriageUrgency {
        let lower = text.lowercased()
        if lower.contains("emergency") || lower.contains("طارئ") || lower.contains("срочно") { return .urgent }
        return .routine
    }

    private func buildTags(urgency: TriageUrgency, specialty: String?, language: AppLanguage) -> [AnalysisTag] {
        var tags: [AnalysisTag] = []
        if let s = specialty { tags.append(AnalysisTag(label: s, color: Color(red: 0.40, green: 0.70, blue: 0.85))) }
        switch urgency {
        case .emergency: tags.append(AnalysisTag(label: language == .arabic ? "طارئ 🔴" : "Срочно 🔴", color: .red))
        case .urgent:    tags.append(AnalysisTag(label: language == .arabic ? "عاجل 🟡" : "Неотложно 🟡", color: .orange))
        case .routine:   tags.append(AnalysisTag(label: language == .arabic ? "روتيني 🟢" : "Плановый 🟢",
                                                  color: Color(red: 0.30, green: 0.72, blue: 0.55)))
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
        if let s = specialty { tags.append(AnalysisTag(label: s, color: Color(red: 0.95, green: 0.70, blue: 0.40))) }
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

    private func notConfiguredResponse(language: AppLanguage) -> AIResponse {
        let text = language == .arabic
            ? "خدمة الذكاء الاصطناعي غير مُهيأة بعد. يرجى التواصل مع الدعم."
            : "AI-сервис ещё не настроен. Пожалуйста, обратитесь в поддержку."
        return AIResponse(text: text, specialty: nil, suggestedDoctors: [],
                          isEmergency: false, analysisCard: nil)
    }

    private func fallbackResponse(language: AppLanguage) -> AIResponse {
        let text = language == .arabic
            ? "عذراً، حدث خطأ في الاتصال. يرجى المحاولة مجدداً."
            : "Произошла ошибка соединения. Пожалуйста, повторите попытку."
        return AIResponse(text: text, specialty: nil, suggestedDoctors: [],
                          isEmergency: false, analysisCard: nil)
    }
}
