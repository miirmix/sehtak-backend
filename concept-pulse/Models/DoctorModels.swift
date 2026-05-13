import SwiftUI

// MARK: - Patient Request

enum RequestStatus: String, CaseIterable {
    case pending, accepted, rejected

    func label(_ lang: AppLanguage) -> String {
        switch (self, lang) {
        case (.pending,  .arabic):  return "معلّق"
        case (.pending,  .russian): return "Ожидает"
        case (.accepted, .arabic):  return "مقبول"
        case (.accepted, .russian): return "Принят"
        case (.rejected, .arabic):  return "مرفوض"
        case (.rejected, .russian): return "Отклонён"
        }
    }
    var color: Color {
        switch self {
        case .pending:  return Color(red: 0.95, green: 0.70, blue: 0.25)
        case .accepted: return Color(red: 0.20, green: 0.70, blue: 0.45)
        case .rejected: return Color(red: 0.90, green: 0.30, blue: 0.35)
        }
    }
}

struct PatientRequest: Identifiable, Hashable {
    let id: UUID
    let patientNameAr: String
    let patientNameRu: String
    let symptomsAr: String
    let symptomsRu: String
    let medNotesAr: String
    let medNotesRu: String
    let requestedDateAr: String
    let requestedDateRu: String
    let requestedTime: String
    var status: RequestStatus
    let avatarColor: Color
    let initials: String

    var displayName: String    { Loc.lang == .arabic ? patientNameAr : patientNameRu }
    var displaySymptoms: String { Loc.lang == .arabic ? symptomsAr : symptomsRu }
    var displayNotes: String    { Loc.lang == .arabic ? medNotesAr : medNotesRu }
    var displayDate: String     { Loc.lang == .arabic ? requestedDateAr : requestedDateRu }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: PatientRequest, rhs: PatientRequest) -> Bool { lhs.id == rhs.id }
}

// MARK: - Sample Patient Requests

extension SampleData {
    static var patientRequests: [PatientRequest] = [
        PatientRequest(
            id: UUID(),
            patientNameAr: "سلمى الأحمد",
            patientNameRu: "Сальма Аль-Ахмад",
            symptomsAr: "ألم في أسفل الظهر، تعب عام، تورم في القدمين",
            symptomsRu: "Боль в пояснице, общая усталость, отёки ног",
            medNotesAr: "ضغط الدم مرتفع منذ ٣ سنوات. لا تأخذ أدوية حالياً.",
            medNotesRu: "Гипертония в течение 3 лет. В настоящее время без лечения.",
            requestedDateAr: "الإثنين، ١٨ نوفمبر",
            requestedDateRu: "Понедельник, 18 ноября",
            requestedTime: "10:00",
            status: .pending,
            avatarColor: Color(red: 0.75, green: 0.55, blue: 0.85),
            initials: "سأ"
        ),
        PatientRequest(
            id: UUID(),
            patientNameAr: "ياسر المطيري",
            patientNameRu: "Ясер Аль-Мутайри",
            symptomsAr: "صداع متكرر، ارتفاع الضغط، بول رغوي",
            symptomsRu: "Частые головные боли, высокое давление, пенистая моча",
            medNotesAr: "مريض سكري منذ ١٠ سنوات. مستوى السكر غير منضبط.",
            medNotesRu: "Диабет 10 лет. Уровень сахара нестабилен.",
            requestedDateAr: "الثلاثاء، ١٩ نوفمبر",
            requestedDateRu: "Вторник, 19 ноября",
            requestedTime: "14:30",
            status: .pending,
            avatarColor: Color(red: 0.40, green: 0.70, blue: 0.85),
            initials: "يم"
        ),
        PatientRequest(
            id: UUID(),
            patientNameAr: "هند الشمري",
            patientNameRu: "Хинд Аш-Шаммари",
            symptomsAr: "غثيان، فقدان شهية، ألم في البطن",
            symptomsRu: "Тошнота, потеря аппетита, боли в животе",
            medNotesAr: "لا أمراض مزمنة. التحاليل الأخيرة قبل شهر.",
            medNotesRu: "Нет хронических заболеваний. Последние анализы месяц назад.",
            requestedDateAr: "الأربعاء، ٢٠ نوفمبر",
            requestedDateRu: "Среда, 20 ноября",
            requestedTime: "11:00",
            status: .accepted,
            avatarColor: Color(red: 0.90, green: 0.40, blue: 0.45),
            initials: "هش"
        ),
        PatientRequest(
            id: UUID(),
            patientNameAr: "فهد العنزي",
            patientNameRu: "Фахд Аль-Анзи",
            symptomsAr: "آلام مفاصل، تعب، انخفاض التركيز",
            symptomsRu: "Боли в суставах, усталость, снижение концентрации",
            medNotesAr: "لا يوجد تاريخ طبي سابق.",
            medNotesRu: "Нет предшествующей медицинской истории.",
            requestedDateAr: "الخميس، ٢١ نوفمبر",
            requestedDateRu: "Четверг, 21 ноября",
            requestedTime: "09:30",
            status: .rejected,
            avatarColor: Color(red: 0.50, green: 0.75, blue: 0.60),
            initials: "فع"
        )
    ]
}
