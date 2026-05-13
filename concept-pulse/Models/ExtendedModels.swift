import SwiftUI

// MARK: - Extended Doctor

struct DoctorDetail: Identifiable, Hashable {
    let id: UUID
    let nameAr: String
    let nameRu: String
    let specialtyAr: String
    let specialtyRu: String
    let specialtyKey: String   // for AI matching
    let cityAr: String
    let cityRu: String
    let rating: Double
    let reviews: Int
    let yearsExp: Int
    let nextSlotAr: String
    let avatarColor: Color
    let initials: String
    let consultationFee: Int   // SAR
    let addressAr: String
    let bio: String
    let availableDates: [AvailableDay]

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: DoctorDetail, rhs: DoctorDetail) -> Bool { lhs.id == rhs.id }

    var displayName: String { Loc.lang == .arabic ? nameAr : nameRu }
    var displaySpecialty: String { Loc.lang == .arabic ? specialtyAr : specialtyRu }
    var displayCity: String { Loc.lang == .arabic ? cityAr : cityRu }
}

struct AvailableDay: Identifiable {
    let id = UUID()
    let dateAr: String
    let dateRu: String
    let dateValue: Date
    let slots: [String]

    var displayDate: String { Loc.lang == .arabic ? dateAr : dateRu }
}

// MARK: - Medical Record

struct MedicalRecord: Identifiable {
    let id = UUID()
    let type: RecordType
    let titleAr: String
    let titleRu: String
    let dateAr: String
    let doctorAr: String
    let summary: String
    let values: [LabValue]
    let date: Date

    var displayTitle: String { Loc.lang == .arabic ? titleAr : titleRu }
}

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

// MARK: - Extended Appointment

extension Appointment {
    var statusColor: Color {
        isUpcoming ? AppTheme.success : AppTheme.textSecondary.opacity(0.6)
    }
    var statusAr: String { isUpcoming ? "قادم" : "مكتمل" }
    var statusRu: String { isUpcoming ? "Предстоит" : "Завершён" }
    var displayStatus: String { Loc.lang == .arabic ? statusAr : statusRu }
}

// MARK: - Sample Data Extended

extension SampleData {
    static let doctorDetails: [DoctorDetail] = [
        DoctorDetail(
            id: UUID(),
            nameAr: "د. أحمد المنصور",
            nameRu: "Д-р Ахмад Аль-Мансур",
            specialtyAr: "طبيب قلب",
            specialtyRu: "Кардиолог",
            specialtyKey: "قلب",
            cityAr: "الرياض",
            cityRu: "Эр-Рияд",
            rating: 4.9, reviews: 312, yearsExp: 14,
            nextSlotAr: "اليوم ٤:٣٠ م",
            avatarColor: Color(red: 0.90, green: 0.40, blue: 0.45),
            initials: "أم",
            consultationFee: 250,
            addressAr: "مجمع عيادات النخبة، شارع العليا، الرياض",
            bio: "استشاري أمراض القلب والأوعية الدموية، حاصل على البورد الأمريكي. خبرة ١٤ عاماً في علاج أمراض القلب التاجية وضعف عضلة القلب.",
            availableDates: makeSlots()
        ),
        DoctorDetail(
            id: UUID(),
            nameAr: "د. ليلى الحارثي",
            nameRu: "Д-р Лейла Аль-Хариси",
            specialtyAr: "طبيبة أطفال",
            specialtyRu: "Педиатр",
            specialtyKey: "أطفال",
            cityAr: "جدة",
            cityRu: "Джидда",
            rating: 4.8, reviews: 245, yearsExp: 10,
            nextSlotAr: "غداً ١٠:٠٠ ص",
            avatarColor: Color(red: 0.95, green: 0.70, blue: 0.40),
            initials: "لح",
            consultationFee: 200,
            addressAr: "مركز صحة الطفل، حي الروضة، جدة",
            bio: "استشارية طب الأطفال، متخصصة في صحة حديثي الولادة والأطفال حتى سن ١٢ عاماً.",
            availableDates: makeSlots()
        ),
        DoctorDetail(
            id: UUID(),
            nameAr: "د. خالد العبدالله",
            nameRu: "Д-р Халид Аль-Абдулла",
            specialtyAr: "طبيب أسنان",
            specialtyRu: "Стоматолог",
            specialtyKey: "أسنان",
            cityAr: "الدمام",
            cityRu: "Даммам",
            rating: 4.9, reviews: 401, yearsExp: 18,
            nextSlotAr: "اليوم ٧:٠٠ م",
            avatarColor: Color(red: 0.40, green: 0.70, blue: 0.85),
            initials: "خع",
            consultationFee: 180,
            addressAr: "عيادة الابتسامة البيضاء، شارع الملك فهد، الدمام",
            bio: "متخصص في تجميل الأسنان وزراعة العظام. حاصل على دكتوراه من جامعة الملك سعود.",
            availableDates: makeSlots()
        ),
        DoctorDetail(
            id: UUID(),
            nameAr: "د. سارة القحطاني",
            nameRu: "Д-р Сара Аль-Кахтани",
            specialtyAr: "جلدية وتجميل",
            specialtyRu: "Дерматолог",
            specialtyKey: "جلدية",
            cityAr: "الرياض",
            cityRu: "Эр-Рияд",
            rating: 4.7, reviews: 189, yearsExp: 8,
            nextSlotAr: "بعد غد ٢:٠٠ م",
            avatarColor: Color(red: 0.75, green: 0.55, blue: 0.85),
            initials: "سق",
            consultationFee: 220,
            addressAr: "مركز الجلد والتجميل، حي الملقا، الرياض",
            bio: "متخصصة في أمراض الجلد والتجميل الطبي. خبرة واسعة في علاج حب الشباب والأكزيما والبهاق.",
            availableDates: makeSlots()
        ),
        DoctorDetail(
            id: UUID(),
            nameAr: "د. محمد الغامدي",
            nameRu: "Д-р Мухаммад Аль-Гамди",
            specialtyAr: "باطنة وسكري",
            specialtyRu: "Эндокринолог",
            specialtyKey: "باطنة",
            cityAr: "الرياض",
            cityRu: "Эр-Рияд",
            rating: 4.8, reviews: 278, yearsExp: 12,
            nextSlotAr: "غداً ٩:٠٠ ص",
            avatarColor: Color(red: 0.30, green: 0.70, blue: 0.70),
            initials: "مغ",
            consultationFee: 230,
            addressAr: "مستشفى الدكتور سليمان الحبيب، الرياض",
            bio: "استشاري أمراض الباطنة والغدد الصماء، متخصص في مرض السكري وضغط الدم وأمراض الغدة الدرقية.",
            availableDates: makeSlots()
        ),
        DoctorDetail(
            id: UUID(),
            nameAr: "د. نورا العمري",
            nameRu: "Д-р Нора Аль-Умари",
            specialtyAr: "طب نفسي",
            specialtyRu: "Психиатр",
            specialtyKey: "نفسي",
            cityAr: "جدة",
            cityRu: "Джидда",
            rating: 4.9, reviews: 156, yearsExp: 9,
            nextSlotAr: "بعد غد ٤:٠٠ م",
            avatarColor: Color(red: 0.85, green: 0.55, blue: 0.70),
            initials: "نع",
            consultationFee: 300,
            addressAr: "مركز الصحة النفسية، حي الزهراء، جدة",
            bio: "استشارية الطب النفسي والعلاج السلوكي المعرفي. خبرة في علاج القلق والاكتئاب وضغط ما بعد الصدمة.",
            availableDates: makeSlots()
        )
    ]

    private static func makeSlots() -> [AvailableDay] {
        let base = Date()
        return [
            AvailableDay(dateAr: "اليوم", dateRu: "Сегодня", dateValue: base,
                         slots: ["٤:٠٠ م", "٤:٣٠ م", "٥:٠٠ م", "٥:٣٠ م"]),
            AvailableDay(dateAr: "غداً", dateRu: "Завтра", dateValue: base.addingTimeInterval(86400),
                         slots: ["٩:٠٠ ص", "٩:٣٠ ص", "١٠:٠٠ ص", "٢:٠٠ م", "٢:٣٠ م"]),
            AvailableDay(dateAr: "بعد غد", dateRu: "Послезавтра", dateValue: base.addingTimeInterval(172800),
                         slots: ["١١:٠٠ ص", "١١:٣٠ ص", "٣:٠٠ م", "٣:٣٠ م"])
        ]
    }

    static let appointments: [Appointment] = [
        Appointment(doctor: doctors[0], dateAr: "الإثنين، ١٨ نوفمبر",
                    timeAr: "٤:٣٠ مساءً", locationAr: "مجمع عيادات النخبة، الرياض", isUpcoming: true),
        Appointment(doctor: doctors[1], dateAr: "الأربعاء، ٢٠ نوفمبر",
                    timeAr: "١٠:٠٠ صباحاً", locationAr: "مركز صحة الطفل، جدة", isUpcoming: true),
        Appointment(doctor: doctors[2], dateAr: "الخميس، ٣ أكتوبر",
                    timeAr: "٧:٠٠ مساءً", locationAr: "عيادة الابتسامة البيضاء، الدمام", isUpcoming: false),
        Appointment(doctor: doctors[3], dateAr: "السبت، ٢١ سبتمبر",
                    timeAr: "٢:٠٠ ظهراً", locationAr: "مركز الجلد، الرياض", isUpcoming: false)
    ]

    static let medicalRecords: [MedicalRecord] = [
        MedicalRecord(
            type: .bloodTest,
            titleAr: "تحليل الدم الشامل CBC",
            titleRu: "Общий анализ крови CBC",
            dateAr: "١٠ نوفمبر ٢٠٢٤",
            doctorAr: "د. محمد الغامدي",
            summary: "نتائج التحليل في المستوى الطبيعي عموماً مع ملاحظة انخفاض طفيف في الهيموجلوبين.",
            values: [
                LabValue(name: "الهيموجلوبين", value: "11.2", unit: "g/dL", normalRange: "12-16", isAbnormal: true),
                LabValue(name: "خلايا الدم البيضاء", value: "7.2", unit: "×10³/μL", normalRange: "4-11", isAbnormal: false),
                LabValue(name: "الصفائح الدموية", value: "245", unit: "×10³/μL", normalRange: "150-400", isAbnormal: false),
                LabValue(name: "السكر الصيامي", value: "95", unit: "mg/dL", normalRange: "70-100", isAbnormal: false)
            ],
            date: Date().addingTimeInterval(-259200)
        ),
        MedicalRecord(
            type: .ecg,
            titleAr: "تخطيط قلب ECG",
            titleRu: "Электрокардиограмма ЭКГ",
            dateAr: "٥ نوفمبر ٢٠٢٤",
            doctorAr: "د. أحمد المنصور",
            summary: "إيقاع جيبي طبيعي. معدل ضربات القلب ٧٢ في الدقيقة. لا يوجد تغييرات إقفارية.",
            values: [
                LabValue(name: "معدل ضربات القلب", value: "72", unit: "bpm", normalRange: "60-100", isAbnormal: false),
                LabValue(name: "QRS", value: "0.08", unit: "ثانية", normalRange: "0.06-0.10", isAbnormal: false)
            ],
            date: Date().addingTimeInterval(-691200)
        ),
        MedicalRecord(
            type: .prescription,
            titleAr: "وصفة طبية - أوميغا ٣ وفيتامين د",
            titleRu: "Рецепт - Омега-3 и витамин Д",
            dateAr: "١٠ نوفمبر ٢٠٢٤",
            doctorAr: "د. محمد الغامدي",
            summary: "أوميغا ٣ - كبسولة واحدة يومياً. فيتامين د ٢٠٠٠ وحدة يومياً. مدة العلاج ٣ أشهر.",
            values: [],
            date: Date().addingTimeInterval(-259200)
        ),
        MedicalRecord(
            type: .visitNote,
            titleAr: "ملاحظة زيارة - متابعة ضغط الدم",
            titleRu: "Запись посещения - контроль давления",
            dateAr: "٢١ سبتمبر ٢٠٢٤",
            doctorAr: "د. سارة القحطاني",
            summary: "ضغط الدم ١٢٠/٨٠. حالة مستقرة. يُنصح بالمتابعة كل ٣ أشهر والحفاظ على النشاط البدني.",
            values: [
                LabValue(name: "ضغط الدم", value: "120/80", unit: "mmHg", normalRange: "<130/80", isAbnormal: false),
                LabValue(name: "الوزن", value: "82", unit: "kg", normalRange: "BMI طبيعي", isAbnormal: false)
            ],
            date: Date().addingTimeInterval(-4665600)
        )
    ]
}
