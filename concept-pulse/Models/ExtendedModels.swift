import SwiftUI

// MARK: - Extended Doctor

struct DoctorDetail: Identifiable, Hashable {
    let id: UUID
    let nameAr: String
    let nameRu: String
    let specialtyAr: String
    let specialtyRu: String
    let specialtyKey: String
    let cityAr: String
    let cityRu: String
    let rating: Double
    let reviews: Int
    let yearsExp: Int
    let nextSlotAr: String
    let avatarColor: Color
    let initials: String
    let consultationFee: Int
    let addressAr: String
    let bio: String
    let availableDates: [AvailableDay]

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: DoctorDetail, rhs: DoctorDetail) -> Bool { lhs.id == rhs.id }

    var displayName: String      { loc(nameAr, nameRu) }
    var displaySpecialty: String { loc(specialtyAr, specialtyRu) }
    var displayCity: String      { loc(cityAr, cityRu) }
    var displayNextSlot: String  { nextSlotAr }
}

struct AvailableDay: Identifiable {
    let id = UUID()
    let dateAr: String
    let dateRu: String
    let dateValue: Date
    let slots: [String]
    var displayDate: String { loc(dateAr, dateRu) }
}

// MARK: - Medical Record

struct MedicalRecord: Identifiable {
    let id = UUID()
    let type: RecordType
    let titleAr: String
    let titleRu: String
    let dateAr: String
    let dateRu: String
    let doctorAr: String
    let doctorRu: String
    let summaryAr: String
    let summaryRu: String
    let values: [LabValue]
    let date: Date

    var summary: String       { loc(summaryAr, summaryRu) }
    var displayTitle: String  { loc(titleAr, titleRu) }
    var displayDate: String   { loc(dateAr, dateRu) }
    var displayDoctor: String { loc(doctorAr, doctorRu) }
}

// MARK: - Record Types

enum RecordType: String {
    case bloodTest, ecg, prescription, visitNote, imaging

    var icon: String {
        switch self {
        case .bloodTest: return "drop.fill"
        case .ecg: return "waveform.path.ecg"
        case .prescription: return "pills.fill"
        case .visitNote: return "note.text"
        case .imaging: return "photo.fill"
        }
    }
    var color: Color {
        switch self {
        case .bloodTest: return Color(red: 0.90, green: 0.36, blue: 0.42)
        case .ecg: return Color(red: 0.40, green: 0.70, blue: 0.85)
        case .prescription: return Color(red: 0.50, green: 0.75, blue: 0.60)
        case .visitNote: return Color(red: 0.95, green: 0.70, blue: 0.40)
        case .imaging: return Color(red: 0.75, green: 0.55, blue: 0.85)
        }
    }
}

struct LabValue: Identifiable {
    let id = UUID()
    let name: String
    let value: String
    let unit: String
    let normalRange: String
    let isAbnormal: Bool
}

// MARK: - Appointment extension

extension Appointment {
    var statusColor: Color {
        isUpcoming ? AppTheme.success : AppTheme.textSecondary.opacity(0.6)
    }
    var statusAr: String { isUpcoming ? "قادم" : "مكتمل" }
    var statusRu: String { isUpcoming ? "Предстоит" : "Завершён" }
    var displayStatus: String { loc(statusAr, statusRu) }
}

// MARK: - Sample Data Extended

extension SampleData {

    // MARK: Doctors
    static let doctorDetails: [DoctorDetail] = [
        DoctorDetail(
            id: UUID(),
            nameAr: "د. أحمد المنصور",   nameRu: "Д-р Ахмад Мансуров",
            specialtyAr: "طبيب قلب",      specialtyRu: "Кардиолог",
            specialtyKey: "قلب",
            cityAr: "الرياض",             cityRu: "Эр-Рияд",
            rating: 4.9, reviews: 312, yearsExp: 14,
            nextSlotAr: "اليوم ٤:٣٠ م",
            avatarColor: Color(red: 0.90, green: 0.40, blue: 0.45),
            initials: "أم", consultationFee: 250,
            addressAr: "مجمع عيادات النخبة، شارع العليا، الرياض",
            bio: "استشاري أمراض القلب والأوعية الدموية، حاصل على البورد الأمريكي.",
            availableDates: makeSlots()
        ),
        DoctorDetail(
            id: UUID(),
            nameAr: "د. ليلى الحارثي",   nameRu: "Д-р Лейла Хариси",
            specialtyAr: "طبيبة أطفال",  specialtyRu: "Педиатр",
            specialtyKey: "أطفال",
            cityAr: "جدة",               cityRu: "Джидда",
            rating: 4.8, reviews: 245, yearsExp: 10,
            nextSlotAr: "غداً ١٠:٠٠ ص",
            avatarColor: Color(red: 0.95, green: 0.70, blue: 0.40),
            initials: "لح", consultationFee: 200,
            addressAr: "مركز صحة الطفل، حي الروضة، جدة",
            bio: "استشارية طب الأطفال، متخصصة في صحة حديثي الولادة.",
            availableDates: makeSlots()
        ),
        DoctorDetail(
            id: UUID(),
            nameAr: "د. خالد العبدالله", nameRu: "Д-р Халид Абдулла",
            specialtyAr: "طبيب أسنان",   specialtyRu: "Стоматолог",
            specialtyKey: "أسنان",
            cityAr: "الدمام",            cityRu: "Даммам",
            rating: 4.9, reviews: 401, yearsExp: 18,
            nextSlotAr: "اليوم ٧:٠٠ م",
            avatarColor: Color(red: 0.40, green: 0.70, blue: 0.85),
            initials: "خع", consultationFee: 180,
            addressAr: "عيادة الابتسامة البيضاء، شارع الملك فهد، الدمام",
            bio: "متخصص في تجميل الأسنان وزراعة العظام.",
            availableDates: makeSlots()
        ),
        DoctorDetail(
            id: UUID(),
            nameAr: "د. سارة القحطاني",  nameRu: "Д-р Сара Кахтани",
            specialtyAr: "جلدية وتجميل", specialtyRu: "Дерматолог",
            specialtyKey: "جلدية",
            cityAr: "الرياض",            cityRu: "Эр-Рияд",
            rating: 4.7, reviews: 189, yearsExp: 8,
            nextSlotAr: "بعد غد ٢:٠٠ م",
            avatarColor: Color(red: 0.75, green: 0.55, blue: 0.85),
            initials: "سق", consultationFee: 220,
            addressAr: "مركز الجلد والتجميل، حي الملقا، الرياض",
            bio: "متخصصة في أمراض الجلد والتجميل الطبي.",
            availableDates: makeSlots()
        ),
        DoctorDetail(
            id: UUID(),
            nameAr: "د. محمد الغامدي",   nameRu: "Д-р Мухаммад Гамди",
            specialtyAr: "باطنة وسكري",  specialtyRu: "Эндокринолог",
            specialtyKey: "باطنة",
            cityAr: "الرياض",            cityRu: "Эр-Рияд",
            rating: 4.8, reviews: 278, yearsExp: 12,
            nextSlotAr: "غداً ٩:٠٠ ص",
            avatarColor: Color(red: 0.30, green: 0.70, blue: 0.70),
            initials: "مغ", consultationFee: 230,
            addressAr: "مستشفى الدكتور سليمان الحبيب، الرياض",
            bio: "استشاري أمراض الباطنة والغدد الصماء.",
            availableDates: makeSlots()
        ),
        DoctorDetail(
            id: UUID(),
            nameAr: "د. نورا العمري",    nameRu: "Д-р Нора Умари",
            specialtyAr: "طب نفسي",      specialtyRu: "Психиатр",
            specialtyKey: "نفسي",
            cityAr: "جدة",              cityRu: "Джидда",
            rating: 4.9, reviews: 156, yearsExp: 9,
            nextSlotAr: "بعد غد ٤:٠٠ م",
            avatarColor: Color(red: 0.85, green: 0.55, blue: 0.70),
            initials: "نع", consultationFee: 300,
            addressAr: "مركز الصحة النفسية، حي الزهراء، جدة",
            bio: "استشارية الطب النفسي والعلاج السلوكي المعرفي.",
            availableDates: makeSlots()
        )
    ]

    private static func makeSlots() -> [AvailableDay] {
        let base = Date()
        return [
            AvailableDay(dateAr: "اليوم",    dateRu: "Сегодня",      dateValue: base,
                         slots: ["٤:٠٠ م", "٤:٣٠ م", "٥:٠٠ م", "٥:٣٠ م"]),
            AvailableDay(dateAr: "غداً",     dateRu: "Завтра",       dateValue: base.addingTimeInterval(86400),
                         slots: ["٩:٠٠ ص", "٩:٣٠ ص", "١٠:٠٠ ص", "٢:٠٠ م", "٢:٣٠ م"]),
            AvailableDay(dateAr: "بعد غد",   dateRu: "Послезавтра",  dateValue: base.addingTimeInterval(172800),
                         slots: ["١١:٠٠ ص", "١١:٣٠ ص", "٣:٠٠ م", "٣:٣٠ م"])
        ]
    }

    // MARK: Medical Records
    static let medicalRecords: [MedicalRecord] = [
        MedicalRecord(
            type: .bloodTest,
            titleAr: "تحليل الدم الشامل CBC",   titleRu: "Общий анализ крови CBC",
            dateAr: "١٠ نوفمبر ٢٠٢٤",           dateRu: "10 ноября 2024",
            doctorAr: "د. محمد الغامدي",         doctorRu: "Д-р Мухаммад Гамди",
            summaryAr: "نتائج التحليل في المستوى الطبيعي عموماً مع ملاحظة انخفاض طفيف في الهيموجلوبين.",
            summaryRu: "Результаты анализа в целом в норме, отмечается небольшое снижение гемоглобина.",
            values: [
                LabValue(name: loc("الهيموجلوبين", "Гемоглобин"),     value: "11.2", unit: "g/dL",    normalRange: "12–16",  isAbnormal: true),
                LabValue(name: loc("خلايا الدم البيضاء", "Лейкоциты"), value: "7.2",  unit: "×10³/μL", normalRange: "4–11",   isAbnormal: false),
                LabValue(name: loc("الصفائح الدموية", "Тромбоциты"),   value: "245",  unit: "×10³/μL", normalRange: "150–400", isAbnormal: false),
                LabValue(name: loc("السكر الصيامي", "Глюкоза натощак"),value: "95",   unit: "mg/dL",  normalRange: "70–100",  isAbnormal: false)
            ],
            date: Date().addingTimeInterval(-259200)
        ),
        MedicalRecord(
            type: .ecg,
            titleAr: "تخطيط قلب ECG",            titleRu: "Электрокардиограмма ЭКГ",
            dateAr: "٥ نوفمبر ٢٠٢٤",             dateRu: "5 ноября 2024",
            doctorAr: "د. أحمد المنصور",          doctorRu: "Д-р Ахмад Мансуров",
            summaryAr: "إيقاع جيبي طبيعي. معدل ضربات القلب ٧٢ في الدقيقة. لا يوجد تغييرات إقفارية.",
            summaryRu: "Синусовый ритм. Частота сердечных сокращений 72 уд/мин. Ишемических изменений нет.",
            values: [
                LabValue(name: loc("معدل ضربات القلب", "ЧСС"), value: "72",   unit: "bpm",      normalRange: "60–100",   isAbnormal: false),
                LabValue(name: "QRS",                           value: "0.08", unit: loc("ثانية", "с"), normalRange: "0.06–0.10", isAbnormal: false)
            ],
            date: Date().addingTimeInterval(-691200)
        ),
        MedicalRecord(
            type: .prescription,
            titleAr: "وصفة — أوميغا ٣ وفيتامين د",  titleRu: "Рецепт — Омега-3 и витамин D",
            dateAr: "١٠ نوفمبر ٢٠٢٤",                dateRu: "10 ноября 2024",
            doctorAr: "د. محمد الغامدي",              doctorRu: "Д-р Мухаммад Гамди",
            summaryAr: "أوميغا ٣ — كبسولة واحدة يومياً. فيتامين د ٢٠٠٠ وحدة يومياً. مدة العلاج ٣ أشهر.",
            summaryRu: "Омега-3 — 1 капсула в день. Витамин D 2000 МЕ в день. Курс лечения 3 месяца.",
            values: [],
            date: Date().addingTimeInterval(-259200)
        ),
        MedicalRecord(
            type: .visitNote,
            titleAr: "ملاحظة زيارة — متابعة ضغط الدم", titleRu: "Запись посещения — контроль давления",
            dateAr: "٢١ سبتمبر ٢٠٢٤",                  dateRu: "21 сентября 2024",
            doctorAr: "د. سارة القحطاني",               doctorRu: "Д-р Сара Кахтани",
            summaryAr: "ضغط الدم ١٢٠/٨٠. حالة مستقرة. يُنصح بالمتابعة كل ٣ أشهر والحفاظ على النشاط البدني.",
            summaryRu: "Давление 120/80. Состояние стабильное. Рекомендуется наблюдение каждые 3 месяца.",
            values: [
                LabValue(name: loc("ضغط الدم", "Давление"), value: "120/80", unit: "mmHg", normalRange: "<130/80",           isAbnormal: false),
                LabValue(name: loc("الوزن", "Вес"),          value: "82",     unit: "kg",   normalRange: loc("BMI طبيعي", "ИМТ норма"), isAbnormal: false)
            ],
            date: Date().addingTimeInterval(-4665600)
        )
    ]
}
