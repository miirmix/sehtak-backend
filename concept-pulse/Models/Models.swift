import SwiftUI

struct Specialty: Identifiable, Hashable {
    let id = UUID()
    let nameAr: String
    let icon: String
    let color: Color
}

struct Doctor: Identifiable, Hashable {
    let id = UUID()
    let nameAr: String
    let specialtyAr: String
    let cityAr: String
    let rating: Double
    let reviews: Int
    let yearsExp: Int
    let nextSlotAr: String
    let avatarColor: Color
    let initials: String
}

struct Appointment: Identifiable {
    let id = UUID()
    let doctor: Doctor
    let dateAr: String
    let timeAr: String
    let locationAr: String
    let isUpcoming: Bool
}

struct Medication: Identifiable {
    let id = UUID()
    let nameAr: String
    let doseAr: String
    let timeAr: String
    let taken: Bool
}

enum SampleData {
    static let specialties: [Specialty] = [
        .init(nameAr: "أسنان", icon: "mouth.fill", color: Color(red: 0.40, green: 0.70, blue: 0.85)),
        .init(nameAr: "قلب", icon: "heart.fill", color: Color(red: 0.90, green: 0.40, blue: 0.45)),
        .init(nameAr: "أطفال", icon: "figure.2.and.child.holdinghands", color: Color(red: 0.95, green: 0.70, blue: 0.40)),
        .init(nameAr: "جلدية", icon: "hand.raised.fill", color: Color(red: 0.75, green: 0.55, blue: 0.85)),
        .init(nameAr: "عيون", icon: "eye.fill", color: Color(red: 0.45, green: 0.60, blue: 0.85)),
        .init(nameAr: "عظام", icon: "figure.walk", color: Color(red: 0.50, green: 0.75, blue: 0.60)),
        .init(nameAr: "نفسي", icon: "brain.head.profile", color: Color(red: 0.85, green: 0.55, blue: 0.70)),
        .init(nameAr: "باطنة", icon: "stethoscope", color: Color(red: 0.30, green: 0.70, blue: 0.70))
    ]

    static let doctors: [Doctor] = [
        .init(nameAr: "د. أحمد المنصور", specialtyAr: "طبيب قلب", cityAr: "الرياض",
              rating: 4.9, reviews: 312, yearsExp: 14, nextSlotAr: "اليوم ٤:٣٠ م",
              avatarColor: Color(red: 0.90, green: 0.40, blue: 0.45), initials: "أم"),
        .init(nameAr: "د. ليلى الحارثي", specialtyAr: "طبيبة أطفال", cityAr: "جدة",
              rating: 4.8, reviews: 245, yearsExp: 10, nextSlotAr: "غداً ١٠:٠٠ ص",
              avatarColor: Color(red: 0.95, green: 0.70, blue: 0.40), initials: "لح"),
        .init(nameAr: "د. خالد العبدالله", specialtyAr: "طبيب أسنان", cityAr: "الدمام",
              rating: 4.9, reviews: 401, yearsExp: 18, nextSlotAr: "اليوم ٧:٠٠ م",
              avatarColor: Color(red: 0.40, green: 0.70, blue: 0.85), initials: "خع"),
        .init(nameAr: "د. سارة القحطاني", specialtyAr: "جلدية", cityAr: "الرياض",
              rating: 4.7, reviews: 189, yearsExp: 8, nextSlotAr: "بعد غد ٢:٠٠ م",
              avatarColor: Color(red: 0.75, green: 0.55, blue: 0.85), initials: "سق")
    ]

    static let nextAppointment = Appointment(
        doctor: doctors[0],
        dateAr: "الإثنين، ١٨ نوفمبر",
        timeAr: "٤:٣٠ مساءً",
        locationAr: "مجمع عيادات النخبة، الرياض",
        isUpcoming: true
    )

    static let medications: [Medication] = [
        .init(nameAr: "أوميغا ٣", doseAr: "كبسولة واحدة", timeAr: "٨:٠٠ ص", taken: true),
        .init(nameAr: "فيتامين د", doseAr: "قرص واحد", timeAr: "٢:٠٠ م", taken: false),
        .init(nameAr: "ميتفورمين", doseAr: "٥٠٠ ملغ", timeAr: "٩:٠٠ م", taken: false)
    ]
}
