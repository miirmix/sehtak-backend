import SwiftUI

@main
struct SehatyApp: App {
    @StateObject private var appState = AppState.shared

    var body: some Scene {
        WindowGroup {
            RootNavigationView()
                .environmentObject(appState)
                .environment(\.layoutDirection, appState.language.isRTL ? .rightToLeft : .leftToRight)
                .tint(AppTheme.primary)
                .task {
                    NSLog("[Sehaty] Backend URL: \(GigaChatConfig.proxyBaseURL)")
                    NSLog("[Sehaty] Backend configured: \(GigaChatConfig.isConfigured)")
                    await GigaChatProvider().runDiagnostic()
                }
        }
    }
}

struct RootNavigationView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            switch appState.authFlow {
            case .roleSelection:
                RoleSelectionView()
            case .auth:
                AuthView()
            case .app:
                if appState.userRole == .doctor {
                    DoctorRootView()
                } else {
                    RootTabView()
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.authFlow)
    }
}
