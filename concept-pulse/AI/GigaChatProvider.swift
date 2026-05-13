import SwiftUI

// MARK: - GigaChat Provider
// All calls go through the Supabase Edge Function — the GigaChat key never leaves the server.
// Requires a valid Supabase anon JWT in the Authorization header (Edge Function has verify_jwt=true).

final class GigaChatProvider: AIProviderProtocol {

    // MARK: Startup Diagnostic
    /// Fires once to surface OAuth/config errors in logs without a real user query.
    func runDiagnostic() async {
        let body: [String: Any] = ["action": "diagnostic"]
        NSLog("[GigaChat] === Running diagnostic ===")
        do {
            let result = try await callProxy(body: body)
            NSLog("[GigaChat] diagnostic result: provider=%@ hasAuthKey=%@ scope=%@ oauthStatus=%@ errorCode=%@ chatStatus=%@",
                  result["provider"] as? String ?? "?",
                  "\(result["hasAuthKey"] ?? "?")",
                  result["scope"] as? String ?? "?",
                  result["oauthStatus"] as? String ?? "?",
                  result["errorCode"] as? CVarArg ?? "nil" as CVarArg,
                  "\(result["chatStatus"] ?? "?")")
        } catch {
            NSLog("[GigaChat] diagnostic callProxy error: %@", error.localizedDescription)
        }
    }

    // MARK: Full Backend Test (visible in UI)
    /// Calls the gigachat-test edge function (no JWT required) and returns a human-readable report.
    func runFullBackendTest() async -> String {
        let urlString = "https://cjhffbqnajxacrvexxca.supabase.co/functions/v1/gigachat-test"
        NSLog("[GigaChat] === Full backend test ===")
        guard let url = URL(string: urlString) else { return "❌ Bad URL" }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.timeoutInterval = 30
        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            NSLog("[GigaChat] test HTTP status=%d", status)
            guard let raw = String(data: data, encoding: .utf8) else { return "❌ No data" }
            NSLog("[GigaChat] test raw: %@", String(raw.prefix(800)))
            // Parse and format nicely
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return "HTTP \(status)\n\n\(raw.prefix(600))"
            }
            return formatTestResult(json)
        } catch {
            NSLog("[GigaChat] test error: %@", error.localizedDescription)
            return "❌ Network error: \(error.localizedDescription)"
        }
    }

    private func formatTestResult(_ j: [String: Any]) -> String {
        var lines: [String] = []
        lines.append("🕐 \(j["timestamp"] as? String ?? "-")")
        lines.append("")
        let hasKey = j["hasAuthKey"] as? Bool ?? false
        lines.append("🔑 Auth Key: \(hasKey ? "✅ Present" : "❌ Missing")")
        lines.append("   Hint: \(j["keyHint"] as? String ?? "-")")
        lines.append("   Scope: \(j["scope"] as? String ?? "-")")
        lines.append("")
        let oauthOk = j["oauthOk"] as? Bool ?? false
        let oauthStatus = j["oauthStatus"]
        lines.append("🔐 OAuth: \(oauthOk ? "✅ OK" : "❌ Failed")")
        lines.append("   Status: \(oauthStatus ?? "-")")
        if let err = j["oauthError"] as? String {
            lines.append("   Error: \(err.prefix(200))")
        }
        if let tokenLen = j["accessTokenLength"] as? Int {
            lines.append("   Token length: \(tokenLen) chars")
        }
        if let exp = j["tokenExpiresAt"] as? String {
            lines.append("   Expires: \(exp)")
        }
        lines.append("")
        let chatOk = j["chatOk"] as? Bool ?? false
        let chatStatus = j["chatStatus"]
        lines.append("💬 Chat: \(chatOk ? "✅ OK" : "❌ Failed")")
        lines.append("   Status: \(chatStatus ?? "-")")
        if let model = j["modelUsed"] as? String {
            lines.append("   Model: \(model)")
        }
        if let reply = j["chatReplyPreview"] as? String {
            lines.append("   Reply: \(reply.prefix(150))")
        }
        if let err = j["chatError"] as? String {
            lines.append("   Error: \(err.prefix(200))")
        }
        if let code = j["errorCode"] as? String {
            lines.append("")
            lines.append("⚠️ Error code: \(code)")
        }
        return lines.joined(separator: "\n")
    }

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
        NSLog("[GigaChat] generateMedicalResponse calling proxy, lang=%@", language.rawValue)
        let dto: [String: Any]
        do {
            dto = try await callProxy(body: body)
        } catch {
            NSLog("[GigaChat] callProxy threw: %@", error.localizedDescription)
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
        let urlString = SupabaseConfig.aiProxyURL
        NSLog("[GigaChat] callProxy → url=%@", urlString)
        guard let url = URL(string: urlString) else {
            NSLog("[GigaChat] ERROR: bad URL")
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.timeoutInterval = 30
        let bodyData = try JSONSerialization.data(withJSONObject: body)
        request.httpBody = bodyData
        NSLog("[GigaChat] request body size=%d bytes", bodyData.count)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            NSLog("[GigaChat] URLSession error: %@", error.localizedDescription)
            throw error
        }

        guard let http = response as? HTTPURLResponse else {
            NSLog("[GigaChat] ERROR: non-HTTP response")
            throw URLError(.badServerResponse)
        }
        NSLog("[GigaChat] HTTP status=%d, data size=%d bytes", http.statusCode, data.count)

        // Log raw response (first 500 chars) for debugging
        if let raw = String(data: data, encoding: .utf8) {
            let preview = String(raw.prefix(500))
            NSLog("[GigaChat] raw response: %@", preview)
        }

        guard (200...299).contains(http.statusCode) else {
            NSLog("[GigaChat] ERROR: non-2xx status %d", http.statusCode)
            throw URLError(.badServerResponse)
        }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            NSLog("[GigaChat] ERROR: could not parse JSON")
            throw URLError(.cannotParseResponse)
        }
        // Note: do NOT throw on "error" key — v6 edge function returns structured errors
        // as valid 200 JSON with responseText so the app can show a meaningful message.
        NSLog("[GigaChat] success, keys=%@", json.keys.joined(separator: ","))
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
