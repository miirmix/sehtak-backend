import Foundation

// MARK: - Supabase Configuration
// Publishable/anon key is safe to embed in client apps — it has no elevated privileges.
// The actual OpenAI API key lives ONLY in Supabase Edge Function secrets.

enum SupabaseConfig {
    static let projectURL = "https://cjhffbqnajxacrvexxca.supabase.co"
    static let anonKey    = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNqaGZmYnFuYWp4YWNydmV4eGNhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg2OTIyODIsImV4cCI6MjA5NDI2ODI4Mn0.UPSJz4_eSbs_YQNZ-HA06yHnepyseevSCbjE_BT658k"
    static let aiProxyURL = "\(projectURL)/functions/v1/ai-medical-proxy"
}
