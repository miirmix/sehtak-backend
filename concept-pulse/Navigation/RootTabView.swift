import SwiftUI

struct RootTabView: View {
    @State private var selection: Int = 0

    var body: some View {
        TabView(selection: $selection) {
            HomeView()
                .tabItem { Label(L.home, systemImage: "house.fill") }
                .tag(0)

            AppointmentsPlaceholderView()
                .tabItem { Label(L.appointments, systemImage: "calendar") }
                .tag(1)

            AssistantPlaceholderView()
                .tabItem { Label(L.assistant, systemImage: "sparkles") }
                .tag(2)

            RecordsPlaceholderView()
                .tabItem { Label(L.records, systemImage: "doc.text.fill") }
                .tag(3)

            ProfilePlaceholderView()
                .tabItem { Label(L.profile, systemImage: "person.fill") }
                .tag(4)
        }
    }
}

#Preview {
    RootTabView().environment(\.layoutDirection, .rightToLeft)
}
