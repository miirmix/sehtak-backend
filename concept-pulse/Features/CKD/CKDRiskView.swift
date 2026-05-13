import SwiftUI

// MARK: - CKD Risk Result

enum CKDRiskLevel {
    case low, medium, high

    var label: String {
        switch self {
        case .low:    return Loc.riskLow
        case .medium: return Loc.riskMedium
        case .high:   return Loc.riskHigh
        }
    }
    var color: Color {
        switch self {
        case .low:    return Color(red: 0.20, green: 0.70, blue: 0.45)
        case .medium: return Color(red: 0.95, green: 0.70, blue: 0.25)
        case .high:   return Color(red: 0.90, green: 0.30, blue: 0.35)
        }
    }
    var icon: String {
        switch self {
        case .low:    return "checkmark.shield.fill"
        case .medium: return "exclamationmark.triangle.fill"
        case .high:   return "xmark.shield.fill"
        }
    }
    var recommendation: String {
        let ar: String
        let ru: String
        switch self {
        case .low:
            ar = "صحة كلاك جيدة. يُنصح بالمتابعة الدورية سنوياً."
            ru = "Здоровье почек в норме. Рекомендуется ежегодный профилактический осмотр."
        case .medium:
            ar = "يُنصح بمراجعة طبيب باطنة لإجراء فحوصات إضافية."
            ru = "Рекомендуется консультация терапевта для дополнительного обследования."
        case .high:
            ar = "يُنصح بزيارة طبيب الكلى (نيفرولوجيست) في أقرب وقت ممكن."
            ru = "Срочно обратитесь к нефрологу для полного обследования."
        }
        return Loc.lang == .arabic ? ar : ru
    }
}

// MARK: - CKD Input Model

struct CKDInputs {
    var age: String = ""
    var gender: Int = 0          // 0 = male, 1 = female
    var systolicBP: String = ""
    var creatinine: String = ""
    var urea: String = ""
    var glucose: String = ""
    var hemoglobin: String = ""
    var albumin: String = ""
    var egfr: String = ""
    var urineProtein: Int = 0    // 0=none, 1=trace, 2=+, 3=++
    var hasDiabetes: Bool = false
    var hasHypertension: Bool = false
}

// MARK: - CKD Risk View

struct CKDRiskView: View {
    @State private var inputs = CKDInputs()
    @State private var result: CKDRiskLevel? = nil
    @State private var showResult = false

    private var isArabic: Bool { Loc.lang == .arabic }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    disclaimerBanner
                    demographicsSection
                    labValuesSection
                    conditionsSection
                    calculateButton
                    if let res = result, showResult {
                        CKDResultCard(level: res)
                            .transition(.scale.combined(with: .opacity))
                    }
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(AppTheme.bg.ignoresSafeArea())
            .navigationTitle(Loc.ckdTitle)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: Disclaimer

    private var disclaimerBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "info.circle.fill").foregroundStyle(AppTheme.primary)
            Text(Loc.ckdDisclaimer).font(.caption).foregroundStyle(AppTheme.textSecondary)
        }
        .padding(14)
        .background(AppTheme.primarySoft.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: Demographics

    private var demographicsSection: some View {
        sectionCard(title: isArabic ? "المعلومات الديموغرافية" : "Демография") {
            CKDField(label: isArabic ? "العمر (سنة)" : "Возраст (лет)",
                     placeholder: isArabic ? "مثال: ٤٥" : "Например: 45",
                     text: $inputs.age)

            Divider()

            VStack(alignment: isArabic ? .trailing : .leading, spacing: 8) {
                Text(isArabic ? "الجنس" : "Пол")
                    .font(.subheadline.weight(.medium)).foregroundStyle(AppTheme.textPrimary)
                Picker("", selection: $inputs.gender) {
                    Text(isArabic ? "ذكر" : "Мужской").tag(0)
                    Text(isArabic ? "أنثى" : "Женский").tag(1)
                }
                .pickerStyle(.segmented)
            }
            .padding(.vertical, 4)

            Divider()
            CKDField(label: isArabic ? "ضغط الدم الانقباضي (mmHg)" : "Систолическое АД (мм рт. ст.)",
                     placeholder: "120", text: $inputs.systolicBP)
        }
    }

    // MARK: Lab Values

    private var labValuesSection: some View {
        sectionCard(title: isArabic ? "نتائج المختبر" : "Лабораторные показатели") {
            CKDField(label: isArabic ? "كرياتينين المصل (mg/dL)" : "Креатинин сыворотки (мг/дл)",
                     placeholder: "1.0", text: $inputs.creatinine)
            Divider()
            CKDField(label: isArabic ? "اليوريا (mg/dL)" : "Мочевина (мг/дл)",
                     placeholder: "30", text: $inputs.urea)
            Divider()
            CKDField(label: isArabic ? "الجلوكوز (mg/dL)" : "Глюкоза (мг/дл)",
                     placeholder: "90", text: $inputs.glucose)
            Divider()
            CKDField(label: isArabic ? "الهيموجلوبين (g/dL)" : "Гемоглобин (г/дл)",
                     placeholder: "13.5", text: $inputs.hemoglobin)
            Divider()
            CKDField(label: isArabic ? "الألبومين (g/dL)" : "Альбумин (г/дл)",
                     placeholder: "4.0", text: $inputs.albumin)
            Divider()
            CKDField(label: isArabic ? "eGFR (إن توفر، mL/min/1.73m²)" : "eGFR (если есть, мл/мин/1.73м²)",
                     placeholder: isArabic ? "اختياري" : "Необязательно", text: $inputs.egfr)
            Divider()
            VStack(alignment: isArabic ? .trailing : .leading, spacing: 8) {
                Text(isArabic ? "بروتين البول" : "Белок в моче")
                    .font(.subheadline.weight(.medium)).foregroundStyle(AppTheme.textPrimary)
                Picker("", selection: $inputs.urineProtein) {
                    Text(isArabic ? "سلبي" : "Нет").tag(0)
                    Text(isArabic ? "آثار" : "Следы").tag(1)
                    Text("+").tag(2)
                    Text("++").tag(3)
                }
                .pickerStyle(.segmented)
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: Conditions

    private var conditionsSection: some View {
        sectionCard(title: isArabic ? "الأمراض المزمنة" : "Хронические заболевания") {
            Toggle(isArabic ? "مرض السكري" : "Сахарный диабет", isOn: $inputs.hasDiabetes)
                .font(.subheadline)
                .tint(AppTheme.primary)
                .padding(.vertical, 4)
            Divider()
            Toggle(isArabic ? "ضغط الدم المرتفع" : "Артериальная гипертензия", isOn: $inputs.hasHypertension)
                .font(.subheadline)
                .tint(AppTheme.primary)
                .padding(.vertical, 4)
        }
    }

    // MARK: Calculate

    private var calculateButton: some View {
        Button {
            let lvl = calculateRisk()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                result = lvl
                showResult = true
            }
        } label: {
            Text(Loc.calculateRisk)
                .font(.headline).foregroundStyle(.white)
                .frame(maxWidth: .infinity).padding(.vertical, 16)
                .background(AppTheme.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: Helper

    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .trailing, spacing: 0) {
            Text(title).font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: isArabic ? .trailing : .leading)
                .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 10)
            VStack(spacing: 0) { content() }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
        }
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.04), radius: 8)
    }

    // MARK: Risk Calculation (rule-based)

    private func calculateRisk() -> CKDRiskLevel {
        var score = 0

        if let age = Int(inputs.age), age >= 60 { score += 2 }
        if let age = Int(inputs.age), age >= 75 { score += 1 }

        if let bp = Double(inputs.systolicBP), bp >= 140 { score += 2 }
        if let bp = Double(inputs.systolicBP), bp >= 160 { score += 1 }

        if let cr = Double(inputs.creatinine), cr > 1.2 { score += 2 }
        if let cr = Double(inputs.creatinine), cr > 2.0 { score += 2 }

        if let urea = Double(inputs.urea), urea > 50  { score += 1 }
        if let urea = Double(inputs.urea), urea > 100 { score += 2 }

        if let glu = Double(inputs.glucose), glu > 126 { score += 1 }
        if let hgb = Double(inputs.hemoglobin), hgb < 11 { score += 1 }
        if let alb = Double(inputs.albumin), alb < 3.5  { score += 2 }

        if let egfr = Double(inputs.egfr) {
            if egfr < 60 { score += 3 }
            if egfr < 30 { score += 3 }
        }

        score += inputs.urineProtein * 2
        if inputs.hasDiabetes    { score += 2 }
        if inputs.hasHypertension { score += 1 }

        if score >= 12 { return .high }
        if score >= 6  { return .medium }
        return .low
    }
}

// MARK: - CKD Field

struct CKDField: View {
    let label: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: Loc.lang == .arabic ? .trailing : .leading, spacing: 6) {
            Text(label).font(.caption.weight(.medium)).foregroundStyle(AppTheme.textSecondary)
            TextField(placeholder, text: $text)
                .keyboardType(.decimalPad)
                .font(.body)
                .padding(.horizontal, 12).padding(.vertical, 10)
                .background(AppTheme.bg)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(.vertical, 4)
    }
}

// MARK: - CKD Result Card

struct CKDResultCard: View {
    let level: CKDRiskLevel
    private var isArabic: Bool { Loc.lang == .arabic }

    var body: some View {
        VStack(spacing: 16) {
            // Risk icon
            ZStack {
                Circle().fill(level.color.opacity(0.15)).frame(width: 80, height: 80)
                Image(systemName: level.icon).font(.largeTitle).foregroundStyle(level.color)
            }
            Text(level.label).font(.title2.weight(.bold)).foregroundStyle(level.color)
            Text(level.recommendation)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textPrimary)
                .multilineTextAlignment(.center)
            Divider()
            Text(Loc.ckdDisclaimer)
                .font(.caption2).foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: level.color.opacity(0.2), radius: 12)
    }
}
