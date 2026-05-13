import SwiftUI

@main
struct SehatyApp: App {
    @StateObject private var appState = AppState.shared

    var body: some Scene {
        WindowGroup {
            RootTabView()
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
