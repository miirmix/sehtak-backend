import SwiftUI

struct RootTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var selection: Int = 0

    var body: some View {
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
    }
}

#Preview {
    RootTabView()
        .environmentObject(AppState.shared)
        .environment(\.layoutDirection, .rightToLeft)
}
