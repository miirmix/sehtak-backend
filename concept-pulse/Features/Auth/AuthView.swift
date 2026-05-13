import SwiftUI

struct AuthView: View {
    @EnvironmentObject private var appState: AppState
    @State private var isLogin = true
    @State private var profile = UserProfile()
    @State private var showError = false

    private var isArabic: Bool { Loc.lang == .arabic }
    private var isDoctor: Bool { appState.userRole == .doctor }

    var body: some View {
        NavigationStack {
            ZStack { AppTheme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        headerSection
                        segmentedPicker
                        formSection
                        actionButton
                        switchModeRow
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                }
            }
            .navigationBarHidden(true)
            .alert(isArabic ? "يرجى ملء جميع الحقول" : "Заполните все поля", isPresented: $showError) {
                Button(Loc.cancel, role: .cancel) {}
            }
        }
    }

    // MARK: Header

    private var headerSection: some View {
        HStack {
            Button { withAnimation { appState.authFlow = .roleSelection } } label: {
                Image(systemName: isArabic ? "chevron.right" : "chevron.left")
                    .font(.title3.weight(.semibold)).foregroundStyle(AppTheme.primary)
            }
            Spacer()
            VStack(spacing: 4) {
                Text(appState.userRole.displayName(Loc.lang))
                    .font(.headline).foregroundStyle(AppTheme.primary)
                Text(isLogin ? Loc.loginTitle : Loc.registerTitle)
                    .font(.title2.weight(.bold)).foregroundStyle(AppTheme.textPrimary)
            }
            Spacer()
            Image(systemName: appState.userRole.icon)
                .font(.title3).foregroundStyle(AppTheme.primary)
        }
        .padding(.top, 8)
    }

    // MARK: Segment

    private var segmentedPicker: some View {
        HStack(spacing: 0) {
            segmentBtn(title: Loc.loginTitle, tag: true)
            segmentBtn(title: Loc.registerTitle, tag: false)
        }
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 6)
    }

    private func segmentBtn(title: String, tag: Bool) -> some View {
        Button { withAnimation { isLogin = tag } } label: {
            Text(title).font(.subheadline.weight(.semibold))
                .foregroundStyle(isLogin == tag ? .white : AppTheme.textSecondary)
                .frame(maxWidth: .infinity).padding(.vertical, 12)
                .background(isLogin == tag ? AppTheme.gradient : LinearGradient(colors: [Color.clear], startPoint: .leading, endPoint: .trailing))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(4)
    }

    // MARK: Form

    private var formSection: some View {
        VStack(spacing: 14) {
            AuthField(icon: "person.fill", placeholder: Loc.name, text: $profile.name)
            if isDoctor && !isLogin {
                AuthField(icon: "stethoscope", placeholder: Loc.specialty, text: $profile.specialty)
                AuthField(icon: "building.2.fill", placeholder: Loc.clinic, text: $profile.clinic)
            }
            AuthField(icon: "phone.fill", placeholder: Loc.phone, text: $profile.phone)
                .keyboardType(.emailAddress)
            if !isLogin {
                AuthField(icon: "mappin.circle.fill", placeholder: Loc.city, text: $profile.city)
            }
            AuthField(icon: "lock.fill", placeholder: Loc.password, text: $profile.password, isSecure: true)
        }
        .padding(20)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.04), radius: 8)
    }

    // MARK: Action

    private var actionButton: some View {
        Button { handleAuth() } label: {
            Text(isLogin ? Loc.loginTitle : Loc.registerTitle)
                .font(.headline).foregroundStyle(.white)
                .frame(maxWidth: .infinity).padding(.vertical, 16)
                .background(AppTheme.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private var switchModeRow: some View {
        HStack(spacing: 4) {
            Button { withAnimation { isLogin.toggle() } } label: {
                Text(isLogin ? Loc.registerTitle : Loc.loginTitle)
                    .font(.subheadline.weight(.semibold)).foregroundStyle(AppTheme.primary)
            }
            Text(isLogin ? Loc.noAccount : Loc.haveAccount)
                .font(.subheadline).foregroundStyle(AppTheme.textSecondary)
        }
    }

    // MARK: Logic

    private func handleAuth() {
        let nameFilled = !profile.name.trimmingCharacters(in: .whitespaces).isEmpty
        let phoneFilled = !profile.phone.trimmingCharacters(in: .whitespaces).isEmpty
        let passFilled = !profile.password.trimmingCharacters(in: .whitespaces).isEmpty
        guard nameFilled && phoneFilled && passFilled else { showError = true; return }
        appState.userProfile = profile
        appState.isLoggedIn = true
        withAnimation { appState.authFlow = .app }
    }
}

// MARK: - Auth Field

struct AuthField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    @State private var showText = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundStyle(AppTheme.primary)
                .frame(width: 22)
            if isSecure && !showText {
                SecureField(placeholder, text: $text)
                    .font(.body)
            } else {
                TextField(placeholder, text: $text)
                    .font(.body)
            }
            if isSecure {
                Button { showText.toggle() } label: {
                    Image(systemName: showText ? "eye.slash.fill" : "eye.fill")
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 14)
        .background(AppTheme.bg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
