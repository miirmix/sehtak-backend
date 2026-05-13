import SwiftUI

struct RootTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var selection: Int = 0
    @State private var drawerDestination: DrawerDestination? = nil

    var body: some View {
        ZStack {
            TabView(selection: $selection) {
                HomeView()
                    .tabItem { Label(Loc.home, systemImage: "house.fill") }
                    .tag(0)

                AppointmentsView()
                    .tabItem { Label(Loc.appointments, systemImage: "calendar") }
                    .tag(1)

                AssistantView()
                    .tabItem { Label(Loc.assistant, systemImage: "sparkles") }
                    .tag(2)

                MedicalRecordsView()
                    .tabItem { Label(Loc.records, systemImage: "doc.text.fill") }
                    .tag(3)

                ProfileView()
                    .tabItem { Label(Loc.profile, systemImage: "person.fill") }
                    .tag(4)
            }
            .tint(AppTheme.primary)

            // Side Drawer overlay
            if appState.showDrawer {
                SideDrawerView(destination: $drawerDestination)
                    .zIndex(10)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: appState.showDrawer)
        .onChange(of: drawerDestination) { dest in
            handleDrawerNavigation(dest)
        }
    }

    private func handleDrawerNavigation(_ dest: DrawerDestination?) {
        guard let dest else { return }
        switch dest {
        case .upcomingAppts, .pastAppts:  selection = 1
        case .medData, .labAnalysis:      selection = 3
        case .searchDoctor, .doctorsDir:  selection = 0
        case .settings:                   selection = 4
        case .ckdRisk, .loyalty, .invoices, .favDoctors:
            break  // handled by sheets / pushed via home tab if needed
        }
        drawerDestination = nil
    }
}

#Preview {
    RootTabView()
        .environmentObject(AppState.shared)
        .environment(\.layoutDirection, .rightToLeft)
}
