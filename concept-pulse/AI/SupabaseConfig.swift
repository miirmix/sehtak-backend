import Foundation

// MARK: - Supabase Configuration
// Supabase is used only for auth and database.
// GigaChat AI calls now go through the FastAPI proxy (backend/).
// See GigaChatConfig.swift for the AI proxy URL.
//
// The anon key is a publishable key — safe to embed in client apps.
// It has no elevated privileges; Row Level Security enforces data access.

enum SupabaseConfig {
    static let projectURL = "https://cjhffbqnajxacrvexxca.supabase.co"
    static let anonKey    = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNqaGZmYnFuYWp4YWNydmV4eGNhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg2OTIyODIsImV4cCI6MjA5NDI2ODI4Mn0.UPSJz4_eSbs_YQNZ-HA06yHnepyseevSCbjE_BT658k"
}
