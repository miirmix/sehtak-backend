import SwiftUI

// MARK: - Drawer Item Model

struct DrawerItem: Identifiable {
    let id = UUID()
    let icon: String
    let titleAr: String
    let titleRu: String
    let color: Color
    let destination: DrawerDestination

    var title: String { Loc.lang == .arabic ? titleAr : titleRu }
}

enum DrawerDestination: Equatable {
    case upcomingAppts, pastAppts, favDoctors, medData
    case labAnalysis, ckdRisk, loyalty, invoices
    case searchDoctor, doctorsDir, settings, none
}

// MARK: - Side Drawer

struct SideDrawerView: View {
    @EnvironmentObject private var appState: AppState
    @Binding var destination: DrawerDestination?

    private var isArabic: Bool { Loc.lang == .arabic }

    var body: some View {
        ZStack(alignment: isArabic ? .trailing : .leading) {
            // Scrim
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { withAnimation { appState.showDrawer = false } }

            // Drawer panel
            drawerPanel
                .frame(width: 300)
                .frame(maxHeight: .infinity)
                .transition(isArabic
                    ? .move(edge: .trailing)
                    : .move(edge: .leading))
        }
    }

    private var drawerPanel: some View {
        ZStack {
            AppTheme.card.ignoresSafeArea()
            VStack(spacing: 0) {
                drawerHeader
                Divider()
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(sections, id: \.0) { section in
                            sectionBlock(title: section.0, items: section.1)
                        }
                    }
                    .padding(.bottom, 30)
                }
                Divider()
                bottomRow
            }
        }
    }

    // MARK: Header

    private var drawerHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(AppTheme.gradient).frame(width: 54, height: 54)
                Text(initials).font(.title3.weight(.bold)).foregroundStyle(.white)
            }
            VStack(alignment: isArabic ? .trailing : .leading, spacing: 3) {
                Text(displayName).font(.headline).foregroundStyle(AppTheme.textPrimary)
                Text(roleLabel).font(.caption).foregroundStyle(AppTheme.primary)
            }
            .frame(maxWidth: .infinity, alignment: isArabic ? .trailing : .leading)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .padding(.top, 40)
    }

    private var initials: String {
        let n = appState.userProfile.name
        return n.isEmpty ? (isArabic ? "م" : "П") : String(n.prefix(1))
    }
    private var displayName: String {
        appState.userProfile.name.isEmpty
            ? (isArabic ? "محمد أحمد" : "Мухаммад") : appState.userProfile.name
    }
    private var roleLabel: String { appState.userRole.displayName(Loc.lang) }

    // MARK: Sections

    private var sections: [(String, [DrawerItem])] {
        [
            (isArabic ? "المواعيد" : "Записи", [
                DrawerItem(icon: "calendar.badge.clock", titleAr: Loc.upcomingAppts, titleRu: Loc.upcomingAppts, color: AppTheme.primary, destination: .upcomingAppts),
                DrawerItem(icon: "calendar.badge.checkmark", titleAr: Loc.pastAppts, titleRu: Loc.pastAppts, color: AppTheme.success, destination: .pastAppts),
                DrawerItem(icon: "heart.fill", titleAr: Loc.favDoctors, titleRu: Loc.favDoctors, color: AppTheme.danger, destination: .favDoctors)
            ]),
            (isArabic ? "الصحة" : "Здоровье", [
                DrawerItem(icon: "doc.text.fill", titleAr: Loc.medData, titleRu: Loc.medData, color: Color(red: 0.40, green: 0.70, blue: 0.85), destination: .medData),
                DrawerItem(icon: "flask.fill", titleAr: Loc.labAnalysis, titleRu: Loc.labAnalysis, color: Color(red: 0.95, green: 0.70, blue: 0.40), destination: .labAnalysis),
                DrawerItem(icon: "kidneys.fill", titleAr: Loc.ckdRisk, titleRu: Loc.ckdRisk, color: Color(red: 0.75, green: 0.55, blue: 0.85), destination: .ckdRisk)
            ]),
            (isArabic ? "المالية" : "Финансы", [
                DrawerItem(icon: "star.fill", titleAr: Loc.loyaltyPoints, titleRu: Loc.loyaltyPoints, color: AppTheme.warning, destination: .loyalty),
                DrawerItem(icon: "doc.plaintext.fill", titleAr: Loc.invoices, titleRu: Loc.invoices, color: Color(red: 0.50, green: 0.75, blue: 0.60), destination: .invoices)
            ]),
            (isArabic ? "الأطباء" : "Врачи", [
                DrawerItem(icon: "magnifyingglass", titleAr: Loc.searchDoctor, titleRu: Loc.searchDoctor, color: AppTheme.primary, destination: .searchDoctor),
                DrawerItem(icon: "list.bullet.clipboard.fill", titleAr: Loc.doctorsDir, titleRu: Loc.doctorsDir, color: Color(red: 0.30, green: 0.70, blue: 0.70), destination: .doctorsDir)
            ]),
            (isArabic ? "الإعدادات" : "Настройки", [
                DrawerItem(icon: "gearshape.fill", titleAr: Loc.settings, titleRu: Loc.settings, color: AppTheme.textSecondary, destination: .settings)
            ])
        ]
    }

    private func sectionBlock(title: String, items: [DrawerItem]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: isArabic ? .trailing : .leading)
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 6)
            ForEach(items) { item in
                DrawerRow(item: item) {
                    destination = item.destination
                    withAnimation { appState.showDrawer = false }
                }
            }
        }
    }

    // MARK: Bottom

    private var bottomRow: some View {
        VStack(spacing: 12) {
            languageToggle
            logoutBtn
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private var languageToggle: some View {
        HStack(spacing: 10) {
            ForEach(AppLanguage.allCases, id: \.self) { lang in
                Button {
                    withAnimation { appState.language = lang }
                } label: {
                    Text(lang.displayName)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(appState.language == lang ? .white : AppTheme.primary)
                        .frame(maxWidth: .infinity).padding(.vertical, 9)
                        .background(appState.language == lang ? AppTheme.gradient : LinearGradient(colors: [AppTheme.primarySoft], startPoint: .leading, endPoint: .trailing))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }

    private var logoutBtn: some View {
        Button {
            withAnimation { appState.showDrawer = false }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                appState.logout()
            }
        } label: {
            Label(Loc.logout, systemImage: "arrow.right.circle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.danger)
                .frame(maxWidth: .infinity).padding(.vertical, 11)
                .background(AppTheme.danger.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Drawer Row

struct DrawerRow: View {
    let item: DrawerItem
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8).fill(item.color.opacity(0.15)).frame(width: 32, height: 32)
                    Image(systemName: item.icon).font(.caption).foregroundStyle(item.color)
                }
                Text(item.title)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: Loc.lang == .arabic ? .trailing : .leading)
                Image(systemName: Loc.lang == .arabic ? "chevron.left" : "chevron.right")
                    .font(.caption2).foregroundStyle(AppTheme.textSecondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
}
