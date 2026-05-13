import SwiftUI

struct PlaceholderView: View {
    let title: String
    let icon: String
    let messageAr: String

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()
                ZStack {
                    Circle().fill(AppTheme.primarySoft).frame(width: 120, height: 120)
                    Image(systemName: icon)
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(AppTheme.primary)
                }
                Text(title)
                    .font(.title2.weight(.bold))
                Text(messageAr)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Text("قريباً")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.primary)
                    .padding(.horizontal, 14).padding(.vertical, 6)
                    .background(AppTheme.primarySoft)
                    .clipShape(Capsule())

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .background(AppTheme.bg.ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct AppointmentsPlaceholderView: View {
    var body: some View {
        PlaceholderView(
            title: L.appointments,
            icon: "calendar.badge.clock",
            messageAr: "هنا ستجد كل مواعيدك القادمة والسابقة في مكان واحد"
        )
    }
}

struct AssistantPlaceholderView: View {
    var body: some View {
        PlaceholderView(
            title: L.assistant,
            icon: "sparkles",
            messageAr: "مساعدك الطبي الذكي جاهز للإجابة على جميع أسئلتك الصحية"
        )
    }
}

struct RecordsPlaceholderView: View {
    var body: some View {
        PlaceholderView(
            title: L.records,
            icon: "doc.text.fill",
            messageAr: "ملفك الطبي الموحد: التشخيصات، الوصفات، والتقارير"
        )
    }
}

struct ProfilePlaceholderView: View {
    var body: some View {
        PlaceholderView(
            title: L.profile,
            icon: "person.crop.circle.fill",
            messageAr: "إدارة حسابك، الخصوصية، والإعدادات الشخصية"
        )
    }
}
