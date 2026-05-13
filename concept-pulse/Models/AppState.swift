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

// MARK: - User Role

enum UserRole: String, CaseIterable {
    case patient, doctor

    func displayName(_ lang: AppLanguage) -> String {
        switch (self, lang) {
        case (.patient, .arabic): return "مريض"
        case (.patient, .russian): return "Пациент"
        case (.doctor, .arabic): return "طبيب"
        case (.doctor, .russian): return "Врач"
        }
    }
    var icon: String { self == .patient ? "person.fill" : "stethoscope" }
}

// MARK: - Auth State

enum AuthFlow {
    case roleSelection, auth, app
}

struct UserProfile {
    var name: String = ""
    var email: String = ""
    var phone: String = ""
    var city: String = ""
    var password: String = ""
    // Doctor-only
    var specialty: String = ""
    var clinic: String = ""
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
        s("هذا تحليل أولي لأغراض توعوية فقط ولا يُعد تشخيصاً طبياً. يرجى مراجعة الطبيب المختص.",
          "Это предварительный информационный анализ, а не медицинский диагноз. Обратитесь к врачу-специалисту.")
    }
    static var medAnalysis: String { s("تحليل البيانات الطبية", "Анализ медданных") }
    static var doctorRecommend: String { s("اقتراح أطباء", "Подбор врача") }
    static var emergencyWarning: String {
        s("قد تكون هذه الأعراض طارئة. يُنصح بالتواصل مع الإسعاف أو زيارة الطوارئ فوراً.",
          "Эти симптомы могут быть неотложными. Рекомендуется срочно обратиться в скорую помощь или отделение неотложной помощи.")
    }

    // Role & Auth
    static var selectRole: String   { s("اختر نوع حسابك", "Выберите тип аккаунта") }
    static var loginTitle: String   { s("تسجيل الدخول", "Войти") }
    static var registerTitle: String { s("إنشاء حساب", "Регистрация") }
    static var name: String         { s("الاسم الكامل", "Полное имя") }
    static var phone: String        { s("الهاتف أو البريد", "Телефон или e-mail") }
    static var password: String     { s("كلمة المرور", "Пароль") }
    static var city: String         { s("المدينة", "Город") }
    static var specialty: String    { s("التخصص", "Специальность") }
    static var clinic: String       { s("المستشفى / العيادة", "Больница / Клиника") }
    static var continueBtn: String  { s("متابعة", "Продолжить") }
    static var haveAccount: String  { s("لديك حساب بالفعل؟", "Уже есть аккаунт?") }
    static var noAccount: String    { s("ليس لديك حساب؟", "Нет аккаунта?") }

    // Drawer
    static var drawerTitle: String      { s("القائمة", "Меню") }
    static var upcomingAppts: String    { s("المواعيد القادمة", "Предстоящие записи") }
    static var pastAppts: String        { s("المواعيد السابقة", "Прошедшие записи") }
    static var favDoctors: String       { s("الأطباء المفضلون", "Избранные врачи") }
    static var medData: String          { s("بياناتي الطبية", "Мои мед. данные") }
    static var labAnalysis: String      { s("التحاليل المخبرية", "Лабораторные анализы") }
    static var ckdRisk: String          { s("تقييم خطر الكلى", "Оценка риска ХБП") }
    static var loyaltyPoints: String    { s("نقاط الولاء", "Баллы лояльности") }
    static var invoices: String         { s("الفواتير", "Счета") }
    static var searchDoctor: String     { s("البحث عن طبيب", "Поиск врача") }
    static var doctorsDir: String       { s("دليل الأطباء", "Каталог врачей") }
    static var settings: String         { s("الإعدادات", "Настройки") }

    // Doctor Dashboard
    static var patientRequests: String  { s("طلبات المرضى", "Запросы пациентов") }
    static var pending: String          { s("معلّق", "Ожидает") }
    static var accepted: String         { s("مقبول", "Принят") }
    static var rejected: String         { s("مرفوض", "Отклонён") }
    static var accept: String           { s("قبول", "Принять") }
    static var reject: String           { s("رفض", "Отклонить") }
    static var viewDetails: String      { s("عرض التفاصيل", "Детали") }
    static var symptoms: String         { s("الأعراض", "Симптомы") }
    static var medNotes: String         { s("الملاحظات الطبية", "Медицинские заметки") }

    // CKD
    static var ckdTitle: String         { s("تقييم خطر مرض الكلى المزمن", "Оценка риска ХБП") }
    static var ckdDisclaimer: String    { s("هذا التقييم لأغراض توعوية فقط وليس تشخيصاً طبياً.", "Эта оценка носит информационный характер и не является медицинским диагнозом.") }
    static var calculateRisk: String    { s("حساب الخطورة", "Рассчитать риск") }
    static var riskLow: String          { s("خطر منخفض", "Низкий риск") }
    static var riskMedium: String       { s("خطر متوسط", "Средний риск") }
    static var riskHigh: String         { s("خطر مرتفع", "Высокий риск") }
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

    // Auth/Role flow
    @Published var authFlow: AuthFlow = .roleSelection
    @Published var userRole: UserRole = .patient
    @Published var userProfile: UserProfile = UserProfile()
    @Published var isLoggedIn: Bool = false

    // Drawer
    @Published var showDrawer: Bool = false

    static let shared = AppState()
    private init() { Loc.lang = .arabic }

    func cancelAppointment(_ id: UUID) {
        appointments.removeAll { $0.id == id }
    }

    func addAppointment(_ appt: Appointment) {
        appointments.insert(appt, at: 0)
    }

    func logout() {
        isLoggedIn = false
        authFlow = .roleSelection
        userProfile = UserProfile()
    }
}
