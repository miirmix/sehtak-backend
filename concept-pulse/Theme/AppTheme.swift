import SwiftUI

enum AppTheme {
    // Calm, trustworthy healthcare palette - teal/mint with warm accents
    static let primary = Color(red: 0.13, green: 0.55, blue: 0.55)        // Deep teal
    static let primarySoft = Color(red: 0.78, green: 0.92, blue: 0.90)    // Mint mist
    static let accent = Color(red: 0.95, green: 0.62, blue: 0.45)         // Warm coral
    static let success = Color(red: 0.30, green: 0.72, blue: 0.55)        // Health green
    static let warning = Color(red: 0.96, green: 0.76, blue: 0.36)        // Soft amber
    static let danger  = Color(red: 0.90, green: 0.36, blue: 0.42)        // Gentle red

    static let bg = Color(red: 0.97, green: 0.98, blue: 0.98)
    static let card = Color(.systemBackground)
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary

    static let gradient = LinearGradient(
        colors: [Color(red: 0.13, green: 0.55, blue: 0.55),
                 Color(red: 0.20, green: 0.68, blue: 0.65)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static let softGradient = LinearGradient(
        colors: [Color(red: 0.86, green: 0.96, blue: 0.94),
                 Color(red: 0.94, green: 0.98, blue: 0.97)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}

extension View {
    func cardStyle() -> some View {
        self
            .padding(16)
            .background(AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
    }
}

// Arabic-first strings
enum L {
    static let appName = "صحتي"
    static let greeting = "أهلاً"
    static let howAreYou = "كيف حالك اليوم؟"
    static let search = "ابحث عن طبيب أو تخصص"
    static let specialties = "التخصصات"
    static let upcoming = "موعدك القادم"
    static let topDoctors = "أطباء موصى بهم"
    static let aiTools = "أدوات الذكاء الاصطناعي"
    static let aiChat = "المساعد الطبي"
    static let aiChatDesc = "اسأل أي سؤال صحي"
    static let aiImage = "تحليل الصور الطبية"
    static let aiImageDesc = "ارفع صورة لتحليلها"
    static let viewAll = "عرض الكل"
    static let bookNow = "احجز الآن"
    static let medications = "تذكيرات الدواء"
    static let nextDose = "الجرعة القادمة"

    // Tabs
    static let home = "الرئيسية"
    static let appointments = "مواعيدي"
    static let records = "ملفي الطبي"
    static let assistant = "المساعد"
    static let profile = "حسابي"
}
