import SwiftUI

@main
struct SehatyApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(\.layoutDirection, .rightToLeft)
                .tint(AppTheme.primary)
        }
    }
}
