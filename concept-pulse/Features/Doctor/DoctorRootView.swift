import SwiftUI

struct DoctorRootView: View {
    @EnvironmentObject var appState: AppState
    @State private var selection: Int = 0
    @State private var drawerDestination: DrawerDestination? = nil

    private var isArabic: Bool { Loc.lang == .arabic }

    var body: some View {
        ZStack {
            TabView(selection: $selection) {
                DoctorDashboardView()
                    .tabItem { Label(isArabic ? "الرئيسية" : "Главная", systemImage: "house.fill") }
                    .tag(0)

                DoctorAppointmentsView()
                    .tabItem { Label(Loc.appointments, systemImage: "calendar") }
                    .tag(1)

                AssistantView()
                    .tabItem { Label(Loc.assistant, systemImage: "sparkles") }
                    .tag(2)

                DoctorProfileView_Screen()
                    .tabItem { Label(Loc.profile, systemImage: "person.fill") }
                    .tag(3)
            }
            .tint(AppTheme.primary)

            if appState.showDrawer {
                SideDrawerView(destination: $drawerDestination)
                    .zIndex(10)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: appState.showDrawer)
    }
}

// MARK: - Doctor Appointments (shows patients booked with this doctor)

struct DoctorAppointmentsView: View {
    @EnvironmentObject private var appState: AppState
    private var isArabic: Bool { Loc.lang == .arabic }
    private let patientAppts = SampleData.doctorPatientAppointments

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 14) {
                    ForEach(patientAppts) { appt in
                        DoctorPatientApptCard(appt: appt)
                    }
                    Color.clear.frame(height: 20)
                }
                .padding(.horizontal, 16).padding(.top, 16)
            }
            .background(AppTheme.bg.ignoresSafeArea())
            .navigationTitle(Loc.appointments)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct DoctorPatientApptCard: View {
    let appt: PatientAppointment
    private var isArabic: Bool { Loc.lang == .arabic }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(appt.avatarColor.opacity(0.18)).frame(width: 52, height: 52)
                Text(appt.initials).font(.headline.weight(.bold)).foregroundStyle(appt.avatarColor)
            }
            VStack(alignment: isArabic ? .trailing : .leading, spacing: 4) {
                Text(appt.displayName).font(.subheadline.weight(.bold))
                Text(appt.displayReason).font(.caption).foregroundStyle(AppTheme.primary)
                Label(appt.displayDate + " · " + appt.displayTime, systemImage: "calendar")
                    .font(.caption).foregroundStyle(AppTheme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: isArabic ? .trailing : .leading)
            let color = appt.isUpcoming ? AppTheme.success : AppTheme.textSecondary.opacity(0.6)
            Text(appt.isUpcoming ? loc("قادم", "Предстоит") : loc("مكتمل", "Завершён"))
                .font(.caption.weight(.semibold)).foregroundStyle(color)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(color.opacity(0.1)).clipShape(Capsule())
        }
        .padding(16)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.04), radius: 8)
    }
}

// MARK: - Doctor Profile Screen

struct DoctorProfileView_Screen: View {
    @EnvironmentObject private var appState: AppState
    @State private var showLanguagePicker = false
    @State private var showLogoutAlert = false
    private var isArabic: Bool { Loc.lang == .arabic }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    doctorProfileHeader
                    statsRow
                    settingsCard
                    logoutButton
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 16)
            }
            .background(AppTheme.bg.ignoresSafeArea())
            .navigationTitle(Loc.profile)
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog(Loc.language, isPresented: $showLanguagePicker) {
                Button("العربية") { withAnimation { appState.language = .arabic } }
                Button("Русский") { withAnimation { appState.language = .russian } }
                Button(Loc.cancel, role: .cancel) {}
            }
            .alert(Loc.logout, isPresented: $showLogoutAlert) {
                Button(Loc.logout, role: .destructive) { appState.logout() }
                Button(Loc.cancel, role: .cancel) {}
            } message: {
                Text(isArabic ? "هل أنت متأكد من تسجيل الخروج؟" : "Вы уверены, что хотите выйти?")
            }
        }
    }

    private var doctorProfileHeader: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle().fill(AppTheme.gradient).frame(width: 90, height: 90)
                Text(String(appState.userProfile.name.prefix(1).isEmpty ? "د" : appState.userProfile.name.prefix(1)))
                    .font(.largeTitle.weight(.bold)).foregroundStyle(.white)
            }
            VStack(spacing: 4) {
                Text(appState.userProfile.name.isEmpty ? (isArabic ? "د. أحمد الطبيب" : "Д-р Ахмад") : appState.userProfile.name)
                    .font(.title3.weight(.bold))
                Text(appState.userProfile.specialty.isEmpty ? (isArabic ? "طبيب عام" : "Врач общей практики") : appState.userProfile.specialty)
                    .font(.subheadline).foregroundStyle(AppTheme.primary)
                Text(appState.userProfile.clinic.isEmpty ? (isArabic ? "مستشفى الملك فهد" : "Больница Короля Фахда") : appState.userProfile.clinic)
                    .font(.caption).foregroundStyle(AppTheme.textSecondary)
            }
        }
        .padding(20)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.05), radius: 12)
        .padding(.top, 8)
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            statCard(value: "٤٢", label: isArabic ? "مريض هذا الأسبوع" : "Пациентов в неделю")
            statCard(value: "٤.٨", label: isArabic ? "التقييم" : "Рейтинг")
            statCard(value: "١٢", label: isArabic ? "سنة خبرة" : "Лет опыта")
        }
    }

    private func statCard(value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Text(value).font(.title2.weight(.bold)).foregroundStyle(AppTheme.primary)
            Text(label).font(.caption).foregroundStyle(AppTheme.textSecondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 6)
    }

    private var settingsCard: some View {
        VStack(spacing: 0) {
            settingRow(icon: "globe", color: AppTheme.primary,
                       title: Loc.language, value: appState.language.displayName) {
                showLanguagePicker = true
            }
            Divider().padding(.leading, 52)
            settingRow(icon: "bell.fill", color: AppTheme.accent,
                       title: Loc.notifications, value: "") {}
            Divider().padding(.leading, 52)
            settingRow(icon: "lock.fill", color: AppTheme.success,
                       title: Loc.privacy, value: "") {}
        }
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.04), radius: 8)
    }

    private func settingRow(icon: String, color: Color, title: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: isArabic ? "chevron.left" : "chevron.right")
                    .font(.caption).foregroundStyle(AppTheme.textSecondary)
                if !value.isEmpty {
                    Text(value).font(.subheadline).foregroundStyle(AppTheme.textSecondary)
                }
                Text(title).font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: isArabic ? .trailing : .leading)
                ZStack {
                    RoundedRectangle(cornerRadius: 8).fill(color.opacity(0.15)).frame(width: 32, height: 32)
                    Image(systemName: icon).font(.caption).foregroundStyle(color)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    private var logoutButton: some View {
        Button { showLogoutAlert = true } label: {
            Label(Loc.logout, systemImage: "arrow.right.circle.fill")
                .font(.subheadline.weight(.semibold)).foregroundStyle(AppTheme.danger)
                .frame(maxWidth: .infinity).padding(.vertical, 14)
                .background(AppTheme.danger.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}
