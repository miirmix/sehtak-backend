import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showLanguagePicker = false
    @State private var showLogoutAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    profileHeader
                    settingsSections
                    logoutButton
                    Color.clear.frame(height: 20)
                }
                .padding(.horizontal, 16)
            }
            .background(AppTheme.bg.ignoresSafeArea())
            .navigationTitle(Loc.profile)
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog(Loc.language, isPresented: $showLanguagePicker) {
                Button("العربية") { setLang(.arabic) }
                Button("Русский") { setLang(.russian) }
                Button(Loc.cancel, role: .cancel) {}
            }
            .alert(Loc.logout, isPresented: $showLogoutAlert) {
                Button(Loc.logout, role: .destructive) {}
                Button(Loc.cancel, role: .cancel) {}
            } message: {
                Text(Loc.lang == .arabic ? "هل أنت متأكد من تسجيل الخروج؟" : "Вы уверены, что хотите выйти?")
            }
        }
    }

    private func setLang(_ lang: AppLanguage) {
        withAnimation { appState.language = lang }
    }

    // MARK: Header
    private var profileHeader: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle().fill(AppTheme.gradient).frame(width: 90, height: 90)
                Text("م").font(.largeTitle.weight(.bold)).foregroundStyle(.white)
                Circle().stroke(.white, lineWidth: 3).frame(width: 90, height: 90)
            }
            VStack(spacing: 4) {
                Text(Loc.lang == .arabic ? "محمد أحمد العمري" : "Мухаммад Аль-Умари")
                    .font(.title3.weight(.bold))
                Text(Loc.lang == .arabic ? "+٩٦٦ ٥٠ ١٢٣ ٤٥٦٧" : "+966 50 123 4567")
                    .font(.subheadline).foregroundStyle(AppTheme.textSecondary)
            }
            editProfileButton
        }
        .padding(20)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 12)
        .padding(.top, 8)
    }

    private var editProfileButton: some View {
        Text(Loc.lang == .arabic ? "تعديل الملف الشخصي" : "Редактировать профиль")
            .font(.caption.weight(.semibold)).foregroundStyle(AppTheme.primary)
            .padding(.horizontal, 16).padding(.vertical, 8)
            .background(AppTheme.primarySoft.opacity(0.5))
            .clipShape(Capsule())
    }

    // MARK: Settings
    private var settingsSections: some View {
        VStack(spacing: 14) {
            sectionCard(title: Loc.lang == .arabic ? "الإعدادات" : "Настройки") {
                settingRow(icon: "globe", iconColor: AppTheme.primary,
                           title: Loc.language,
                           value: appState.language.displayName) {
                    showLanguagePicker = true
                }
                Divider().padding(.leading, 52)
                toggleRow(icon: "bell.fill", iconColor: AppTheme.accent,
                          title: Loc.notifications,
                          binding: $appState.notificationsEnabled)
                Divider().padding(.leading, 52)
                settingRow(icon: "lock.fill", iconColor: AppTheme.success,
                           title: Loc.privacy, value: "") {}
            }
            sectionCard(title: Loc.lang == .arabic ? "الدعم" : "Поддержка") {
                settingRow(icon: "message.fill", iconColor: Color(red: 0.18, green: 0.68, blue: 0.36),
                           title: Loc.support, value: "") {
                    openWhatsApp()
                }
                Divider().padding(.leading, 52)
                settingRow(icon: "star.fill", iconColor: AppTheme.warning,
                           title: Loc.lang == .arabic ? "قيّم التطبيق" : "Оценить приложение",
                           value: "") {}
            }
            sectionCard(title: Loc.lang == .arabic ? "حول التطبيق" : "О приложении") {
                settingRow(icon: "info.circle.fill", iconColor: AppTheme.textSecondary,
                           title: Loc.lang == .arabic ? "الإصدار ١.٠.٠" : "Версия 1.0.0",
                           value: "") {}
            }
        }
    }

    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .trailing, spacing: 0) {
            Text(title)
                .font(.caption.weight(.semibold)).foregroundStyle(AppTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 10)
            content()
        }
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8)
    }

    private func settingRow(icon: String, iconColor: Color, title: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: "chevron.left").font(.caption).foregroundStyle(AppTheme.textSecondary)
                if !value.isEmpty {
                    Text(value).font(.subheadline).foregroundStyle(AppTheme.textSecondary)
                }
                Text(title).font(.subheadline).frame(maxWidth: .infinity, alignment: .trailing)
                iconBadge(icon: icon, color: iconColor)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    private func toggleRow(icon: String, iconColor: Color, title: String, binding: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            Toggle("", isOn: binding).labelsHidden()
            Text(title).font(.subheadline).frame(maxWidth: .infinity, alignment: .trailing)
            iconBadge(icon: icon, color: iconColor)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }

    private func iconBadge(icon: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous).fill(color.opacity(0.15))
            Image(systemName: icon).font(.caption).foregroundStyle(color)
        }
        .frame(width: 32, height: 32)
    }

    private var logoutButton: some View {
        Button { showLogoutAlert = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.right.circle.fill")
                Text(Loc.logout)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppTheme.danger)
            .frame(maxWidth: .infinity).padding(.vertical, 14)
            .background(AppTheme.danger.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private func openWhatsApp() {
        if let url = URL(string: "https://wa.me/966500000000") {
            UIApplication.shared.open(url)
        }
    }
}
