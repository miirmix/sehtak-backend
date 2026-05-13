import SwiftUI

// MARK: - Localization helper

func L(_ ar: String, _ ru: String) -> String {
    Loc.lang == .arabic ? ar : ru
}

// MARK: - Specialty

struct Specialty: Identifiable, Hashable {
    let id = UUID()
    let nameAr: String
    let nameRu: String
    let icon: String
    let color: Color
    var displayName: String { L(nameAr, nameRu) }
}

// MARK: - Doctor (basic, for appointments)

struct Doctor: Identifiable, Hashable {
    let id = UUID()
    let nameAr: String
    let nameRu: String
    let specialtyAr: String
    let specialtyRu: String
    let cityAr: String
    let cityRu: String
    let rating: Double
    let reviews: Int
    let yearsExp: Int
    let nextSlotAr: String
    let nextSlotRu: String
    let avatarColor: Color
    let initials: String

    var displayName: String      { L(nameAr, nameRu) }
    var displaySpecialty: String { L(specialtyAr, specialtyRu) }
    var displayCity: String      { L(cityAr, cityRu) }
    var displayNextSlot: String  { L(nextSlotAr, nextSlotRu) }
}

// MARK: - Appointment

struct Appointment: Identifiable {
    let id = UUID()
    let doctor: Doctor
    let dateAr: String
    let dateRu: String
    let timeAr: String
    let timeRu: String
    let locationAr: String
    let locationRu: String
    let isUpcoming: Bool

    var displayDate: String     { L(dateAr, dateRu) }
    var displayTime: String     { L(timeAr, timeRu) }
    var displayLocation: String { L(locationAr, locationRu) }
}

// MARK: - Medication

struct Medication: Identifiable {
    let id = UUID()
    let nameAr: String
    let nameRu: String
    let doseAr: String
    let doseRu: String
    let timeAr: String
    let timeRu: String
    let taken: Bool

    var displayName: String { L(nameAr, nameRu) }
    var displayDose: String { L(doseAr, doseRu) }
    var displayTime: String { L(timeAr, timeRu) }
}

// MARK: - Patient (for doctor appointments)

struct PatientAppointment: Identifiable {
    let id = UUID()
    let patientNameAr: String
    let patientNameRu: String
    let dateAr: String
    let dateRu: String
    let timeAr: String
    let timeRu: String
    let reasonAr: String
    let reasonRu: String
    let isUpcoming: Bool
    let avatarColor: Color
    let initials: String

    var displayName: String   { L(patientNameAr, patientNameRu) }
    var displayDate: String   { L(dateAr, dateRu) }
    var displayTime: String   { L(timeAr, timeRu) }
    var displayReason: String { L(reasonAr, reasonRu) }
}

// MARK: - Sample Data

enum SampleData {
    static let specialties: [Specialty] = [
        .init(nameAr: "أسنان",  nameRu: "Стоматология",  icon: "mouth.fill",                    color: Color(red: 0.40, green: 0.70, blue: 0.85)),
        .init(nameAr: "قلب",    nameRu: "Кардиология",    icon: "heart.fill",                    color: Color(red: 0.90, green: 0.40, blue: 0.45)),
        .init(nameAr: "أطفال",  nameRu: "Педиатрия",      icon: "figure.2.and.child.holdinghands", color: Color(red: 0.95, green: 0.70, blue: 0.40)),
        .init(nameAr: "جلدية",  nameRu: "Дерматология",   icon: "hand.raised.fill",              color: Color(red: 0.75, green: 0.55, blue: 0.85)),
        .init(nameAr: "عيون",   nameRu: "Офтальмология",  icon: "eye.fill",                      color: Color(red: 0.45, green: 0.60, blue: 0.85)),
        .init(nameAr: "عظام",   nameRu: "Ортопедия",      icon: "figure.walk",                   color: Color(red: 0.50, green: 0.75, blue: 0.60)),
        .init(nameAr: "نفسي",   nameRu: "Психиатрия",     icon: "brain.head.profile",            color: Color(red: 0.85, green: 0.55, blue: 0.70)),
        .init(nameAr: "باطنة",  nameRu: "Терапия",        icon: "stethoscope",                   color: Color(red: 0.30, green: 0.70, blue: 0.70))
    ]

    static let doctors: [Doctor] = [
        Doctor(nameAr: "د. أحمد المنصور",   nameRu: "Д-р Ахмад Мансуров",
               specialtyAr: "طبيب قلب",    specialtyRu: "Кардиолог",
               cityAr: "الرياض",            cityRu: "Эр-Рияд",
               rating: 4.9, reviews: 312, yearsExp: 14,
               nextSlotAr: "اليوم ٤:٣٠ م", nextSlotRu: "Сегодня 16:30",
               avatarColor: Color(red: 0.90, green: 0.40, blue: 0.45), initials: "أم"),
        Doctor(nameAr: "د. ليلى الحارثي",  nameRu: "Д-р Лейла Хариси",
               specialtyAr: "طبيبة أطفال", specialtyRu: "Педиатр",
               cityAr: "جدة",               cityRu: "Джидда",
               rating: 4.8, reviews: 245, yearsExp: 10,
               nextSlotAr: "غداً ١٠:٠٠ ص", nextSlotRu: "Завтра 10:00",
               avatarColor: Color(red: 0.95, green: 0.70, blue: 0.40), initials: "لح"),
        Doctor(nameAr: "د. خالد العبدالله", nameRu: "Д-р Халид Абдулла",
               specialtyAr: "طبيب أسنان",  specialtyRu: "Стоматолог",
               cityAr: "الدمام",            cityRu: "Даммам",
               rating: 4.9, reviews: 401, yearsExp: 18,
               nextSlotAr: "اليوم ٧:٠٠ م", nextSlotRu: "Сегодня 19:00",
               avatarColor: Color(red: 0.40, green: 0.70, blue: 0.85), initials: "خع"),
        Doctor(nameAr: "د. سارة القحطاني", nameRu: "Д-р Сара Кахтани",
               specialtyAr: "جلدية وتجميل", specialtyRu: "Дерматолог",
               cityAr: "الرياض",            cityRu: "Эр-Рияд",
               rating: 4.7, reviews: 189, yearsExp: 8,
               nextSlotAr: "بعد غد ٢:٠٠ م", nextSlotRu: "Послезавтра 14:00",
               avatarColor: Color(red: 0.75, green: 0.55, blue: 0.85), initials: "سق")
    ]

    static let appointments: [Appointment] = [
        Appointment(doctor: doctors[0],
                    dateAr: "الإثنين، ١٨ نوفمبر", dateRu: "Понедельник, 18 ноября",
                    timeAr: "٤:٣٠ مساءً",          timeRu: "16:30",
                    locationAr: "مجمع عيادات النخبة، الرياض", locationRu: "Клиника «Элит», Эр-Рияд",
                    isUpcoming: true),
        Appointment(doctor: doctors[1],
                    dateAr: "الأربعاء، ٢٠ نوفمبر", dateRu: "Среда, 20 ноября",
                    timeAr: "١٠:٠٠ صباحاً",          timeRu: "10:00",
                    locationAr: "مركز صحة الطفل، جدة", locationRu: "Детский центр здоровья, Джидда",
                    isUpcoming: true),
        Appointment(doctor: doctors[2],
                    dateAr: "الخميس، ٣ أكتوبر",    dateRu: "Четверг, 3 октября",
                    timeAr: "٧:٠٠ مساءً",           timeRu: "19:00",
                    locationAr: "عيادة الابتسامة البيضاء، الدمام", locationRu: "Клиника «Белая улыбка», Даммам",
                    isUpcoming: false),
        Appointment(doctor: doctors[3],
                    dateAr: "السبت، ٢١ سبتمبر",    dateRu: "Суббота, 21 сентября",
                    timeAr: "٢:٠٠ ظهراً",           timeRu: "14:00",
                    locationAr: "مركز الجلد، الرياض", locationRu: "Центр дерматологии, Эр-Рияд",
                    isUpcoming: false)
    ]

    static var nextAppointment: Appointment { appointments[0] }

    static let medications: [Medication] = [
        Medication(nameAr: "أوميغا ٣",  nameRu: "Омега-3",
                   doseAr: "كبسولة واحدة", doseRu: "1 капсула",
                   timeAr: "٨:٠٠ ص",    timeRu: "08:00", taken: true),
        Medication(nameAr: "فيتامين د", nameRu: "Витамин D",
                   doseAr: "قرص واحد",   doseRu: "1 таблетка",
                   timeAr: "٢:٠٠ م",    timeRu: "14:00", taken: false),
        Medication(nameAr: "ميتفورمين", nameRu: "Метформин",
                   doseAr: "٥٠٠ ملغ",   doseRu: "500 мг",
                   timeAr: "٩:٠٠ م",    timeRu: "21:00", taken: false)
    ]

    // Doctor-role appointments: shows patients coming to the doctor
    static let doctorPatientAppointments: [PatientAppointment] = [
        PatientAppointment(
            patientNameAr: "سلمى الأحمد",      patientNameRu: "Сальма Аль-Ахмад",
            dateAr: "الإثنين، ١٨ نوفمبر",       dateRu: "Понедельник, 18 ноября",
            timeAr: "١٠:٠٠ ص",                  timeRu: "10:00",
            reasonAr: "ألم في الصدر ومتابعة",   reasonRu: "Боль в груди и наблюдение",
            isUpcoming: true,
            avatarColor: Color(red: 0.75, green: 0.55, blue: 0.85), initials: "سأ"),
        PatientAppointment(
            patientNameAr: "ياسر المطيري",      patientNameRu: "Ясер Мутайри",
            dateAr: "الثلاثاء، ١٩ نوفمبر",      dateRu: "Вторник, 19 ноября",
            timeAr: "٢:٣٠ م",                   timeRu: "14:30",
            reasonAr: "ارتفاع ضغط الدم",         reasonRu: "Высокое кровяное давление",
            isUpcoming: true,
            avatarColor: Color(red: 0.40, green: 0.70, blue: 0.85), initials: "يم"),
        PatientAppointment(
            patientNameAr: "هند الشمري",         patientNameRu: "Хинд Шаммари",
            dateAr: "الأربعاء، ٢٠ نوفمبر",       dateRu: "Среда, 20 ноября",
            timeAr: "١١:٠٠ ص",                  timeRu: "11:00",
            reasonAr: "متابعة بعد العملية",       reasonRu: "Наблюдение после операции",
            isUpcoming: true,
            avatarColor: Color(red: 0.90, green: 0.40, blue: 0.45), initials: "هش"),
        PatientAppointment(
            patientNameAr: "فهد العنزي",         patientNameRu: "Фахд Анзи",
            dateAr: "الخميس، ٣ أكتوبر",          dateRu: "Четверг, 3 октября",
            timeAr: "٩:٣٠ ص",                   timeRu: "09:30",
            reasonAr: "فحص دوري روتيني",          reasonRu: "Плановый осмотр",
            isUpcoming: false,
            avatarColor: Color(red: 0.50, green: 0.75, blue: 0.60), initials: "فع")
    ]
}
