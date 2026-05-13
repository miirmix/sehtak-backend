import SwiftUI
import Combine

// MARK: - Language

enum AppLanguage: String, CaseIterable {
    case arabic = "ar"
    case russian = "ru"

    var displayName: String {
        switch self {
        case .arabic: return "العربية"
        case .russian: return "Русский"
        }
    }
    var isRTL: Bool { self == .arabic }
}

// MARK: - Localization

enum Loc {
    static var lang: AppLanguage = .arabic

    static func s(_ ar: String, _ ru: String) -> String {
        lang == .arabic ? ar : ru
    }

    // Tabs
    static var home: String       { s("الرئيسية", "Главная") }
    static var appointments: String { s("مواعيدي", "Записи") }
    static var assistant: String  { s("المساعد", "Ассистент") }
    static var records: String    { s("ملفي الطبي", "Мой файл") }
    static var profile: String    { s("حسابي", "Аккаунт") }

    // General
    static var bookNow: String    { s("احجز الآن", "Записаться") }
    static var cancel: String     { s("إلغاء", "Отмена") }
    static var confirm: String    { s("تأكيد", "Подтвердить") }
    static var save: String       { s("حفظ", "Сохранить") }
    static var back: String       { s("رجوع", "Назад") }
    static var search: String     { s("ابحث عن طبيب أو تخصص", "Поиск врача или специальности") }
    static var viewAll: String    { s("عرض الكل", "Смотреть все") }
    static var upcoming: String   { s("القادمة", "Предстоящие") }
    static var past: String       { s("السابقة", "Прошедшие") }
    static var noData: String     { s("لا توجد بيانات", "Нет данных") }

    // Doctor
    static var rating: String     { s("التقييم", "Рейтинг") }
    static var experience: String { s("سنوات الخبرة", "Лет опыта") }
    static var reviews: String    { s("تقييم", "отзывов") }
    static var selectDate: String { s("اختر الموعد", "Выбор даты") }
    static var bookingSuccess: String { s("تم الحجز بنجاح! 🎉", "Запись подтверждена! 🎉") }
    static var availableSlots: String { s("المواعيد المتاحة", "Доступное время") }
    static var consultationFee: String { s("رسوم الاستشارة", "Стоимость приёма") }

    // Appointments
    static var cancelAppt: String { s("إلغاء الموعد", "Отменить запись") }
    static var cancelConfirm: String { s("هل أنت متأكد من إلغاء الموعد؟", "Вы уверены, что хотите отменить запись?") }
    static var apptCancelled: String { s("تم إلغاء الموعد", "Запись отменена") }

    // Records
    static var medicalFile: String { s("ملفي الطبي", "Медицинский файл") }
    static var addRecord: String   { s("إضافة سجل", "Добавить запись") }
    static var bloodTest: String   { s("تحليل الدم", "Анализ крови") }
    static var ecg: String         { s("رسم قلب", "ЭКГ") }
    static var prescription: String { s("وصفة طبية", "Рецепт") }
    static var visitNote: String   { s("ملاحظة زيارة", "Запись посещения") }

    // Profile
    static var personalInfo: String { s("المعلومات الشخصية", "Личные данные") }
    static var language: String    { s("اللغة", "Язык") }
    static var notifications: String { s("الإشعارات", "Уведомления") }
    static var privacy: String     { s("الخصوصية والأمان", "Конфиденциальность") }
    static var support: String     { s("الدعم عبر واتساب", "Поддержка в WhatsApp") }
    static var logout: String      { s("تسجيل الخروج", "Выйти") }

    // AI
    static var aiDisclaimer: String {
        s("هذا ليس تشخيصاً طبياً. يرجى مراجعة الطبيب المختص.",
          "Это не медицинский диагноз. Проконсультируйтесь с врачом.")
    }
    static var medAnalysis: String { s("تحليل البيانات الطبية", "Анализ медданных") }
    static var doctorRecommend: String { s("اقتراح أطباء", "Подбор врача") }
}

// MARK: - App State

final class AppState: ObservableObject {
    @Published var language: AppLanguage = .arabic {
        didSet { Loc.lang = language }
    }
    @Published var appointments: [Appointment] = SampleData.appointments
    @Published var medicalRecords: [MedicalRecord] = SampleData.medicalRecords
    @Published var notificationsEnabled: Bool = true
    @Published var selectedTab: Int = 0

    static let shared = AppState()
    private init() { Loc.lang = .arabic }

    func cancelAppointment(_ id: UUID) {
        appointments.removeAll { $0.id == id }
    }

    func addAppointment(_ appt: Appointment) {
        appointments.insert(appt, at: 0)
    }
}
