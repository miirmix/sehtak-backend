import Foundation

// MARK: - Supabase Configuration
// Publishable/anon key is safe to embed in client apps — it has no elevated privileges.
// GigaChat credentials (GIGACHAT_AUTH_KEY, GIGACHAT_SCOPE) live ONLY in Supabase Edge Function secrets.
// Required secrets: GIGACHAT_AUTH_KEY=<your_authorization_key>, GIGACHAT_SCOPE=GIGACHAT_API_PERS

enum SupabaseConfig {
    static let projectURL = "https://cjhffbqnajxacrvexxca.supabase.co"
    static let anonKey    = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNqaGZmYnFuYWp4YWNydmV4eGNhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg2OTIyODIsImV4cCI6MjA5NDI2ODI4Mn0.UPSJz4_eSbs_YQNZ-HA06yHnepyseevSCbjE_BT658k"
    static let aiProxyURL = "\(projectURL)/functions/v1/ai-medical-proxy"
}
