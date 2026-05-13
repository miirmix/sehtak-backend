import Foundation

// MARK: - GigaChat Proxy Configuration
// ⚠️  Set proxyBaseURL to your deployed Railway/Render URL after deployment.
//     The GIGACHAT_AUTH_KEY lives ONLY on the server — never here.
//
//     Steps:
//     1. Deploy backend/ to Railway or Render (see backend/DEPLOY.md)
//     2. Replace the placeholder URL below with your real hosted URL
//     3. Rebuild the app

enum GigaChatConfig {

    // ── Hosted proxy URL ────────────────────────────────────────────────────
    // Replace with your real Railway/Render URL after deployment, e.g.:
    //   "https://gigachat-proxy-production.up.railway.app"
    //   "https://gigachat-proxy.onrender.com"
    static let proxyBaseURL: String = {
        // Read from Info.plist override first (useful for CI/staging), then fall back.
        if let override = Bundle.main.object(forInfoDictionaryKey: "GIGACHAT_PROXY_URL") as? String,
           !override.isEmpty, override != "$(GIGACHAT_PROXY_URL)" {
            return override
        }
        return "https://placeholder.example.com"   // ← replace after deploying backend
    }()

    // Derived endpoints
    static var chatEndpoint:   String { "\(proxyBaseURL)/ai/chat" }
    static var testEndpoint:   String { "\(proxyBaseURL)/test" }
    static var healthEndpoint: String { "\(proxyBaseURL)/health" }

    // Returns true once a real URL has been configured
    static var isConfigured: Bool {
        !proxyBaseURL.contains("placeholder") && !proxyBaseURL.isEmpty
    }
}
