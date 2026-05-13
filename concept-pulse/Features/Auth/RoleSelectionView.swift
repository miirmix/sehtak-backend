import SwiftUI

struct RoleSelectionView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedRole: UserRole? = nil
    @State private var animateIn = false

    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                headerSection
                Spacer()
                rolesSection
                Spacer()
                continueButton
                languageSwitcher
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .onAppear { animateIn = true }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(AppTheme.gradient).frame(width: 80, height: 80)
                Image(systemName: "cross.case.fill").font(.largeTitle).foregroundStyle(.white)
            }
            .padding(.top, 40)
            .opacity(animateIn ? 1 : 0)
            .scaleEffect(animateIn ? 1 : 0.7)
            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: animateIn)

            Text(Loc.lang == .arabic ? "صحتك بالدني" : "Моё здоровье")
                .font(.title.weight(.bold))
                .foregroundStyle(AppTheme.textPrimary)
                .multilineTextAlignment(.center)
                .opacity(animateIn ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.2), value: animateIn)

            Text(Loc.selectRole)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .opacity(animateIn ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.3), value: animateIn)
        }
    }

    private var rolesSection: some View {
        VStack(spacing: 16) {
            ForEach(UserRole.allCases, id: \.self) { role in
                RoleCard(role: role, isSelected: selectedRole == role) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedRole = role
                    }
                }
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 30)
                .animation(.spring(response: 0.5, dampingFraction: 0.7)
                    .delay(role == .patient ? 0.35 : 0.45), value: animateIn)
            }
        }
    }

    private var continueButton: some View {
        Button {
            guard let role = selectedRole else { return }
            appState.userRole = role
            withAnimation { appState.authFlow = .auth }
        } label: {
            Text(Loc.continueBtn)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(selectedRole != nil ? AppTheme.gradient : LinearGradient(colors: [Color.gray.opacity(0.4)], startPoint: .leading, endPoint: .trailing))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .disabled(selectedRole == nil)
        .padding(.bottom, 12)
    }

    private var languageSwitcher: some View {
        HStack(spacing: 16) {
            ForEach(AppLanguage.allCases, id: \.self) { lang in
                Button {
                    withAnimation { appState.language = lang }
                } label: {
                    Text(lang.displayName)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(appState.language == lang ? AppTheme.primary : AppTheme.textSecondary)
                        .padding(.horizontal, 14).padding(.vertical, 7)
                        .background(appState.language == lang ? AppTheme.primarySoft : Color.clear)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.bottom, 8)
    }
}

// MARK: - Role Card

struct RoleCard: View {
    let role: UserRole
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isSelected ? AppTheme.primary : AppTheme.primarySoft)
                        .frame(width: 56, height: 56)
                    Image(systemName: role.icon)
                        .font(.title2)
                        .foregroundStyle(isSelected ? .white : AppTheme.primary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(role.displayName(Loc.lang))
                        .font(.title3.weight(.bold))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(roleSubtitle)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: Loc.lang.isRTL ? .trailing : .leading)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? AppTheme.primary : AppTheme.textSecondary.opacity(0.4))
            }
            .padding(20)
            .background(AppTheme.card)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isSelected ? AppTheme.primary : Color.clear, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: isSelected ? AppTheme.primary.opacity(0.15) : Color.black.opacity(0.04),
                    radius: isSelected ? 12 : 6)
        }
        .buttonStyle(.plain)
    }

    private var roleSubtitle: String {
        switch (role, Loc.lang) {
        case (.patient, .arabic): return "احجز مواعيد وتابع صحتك"
        case (.patient, .russian): return "Записывайтесь и следите за здоровьем"
        case (.doctor, .arabic): return "أدر عياداتك وطلبات مرضاك"
        case (.doctor, .russian): return "Управляйте приёмами и запросами"
        }
    }
}
