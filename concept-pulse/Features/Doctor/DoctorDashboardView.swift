import SwiftUI

struct DoctorDashboardView: View {
    @EnvironmentObject private var appState: AppState
    @State private var requests = SampleData.patientRequests
    @State private var selectedRequest: PatientRequest? = nil

    private var isArabic: Bool { Loc.lang == .arabic }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    doctorHeader
                    statsStrip
                    requestsSection
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(AppTheme.bg.ignoresSafeArea())
            .navigationBarHidden(true)
            .navigationDestination(item: $selectedRequest) { req in
                PatientRequestDetailView(request: req) { updatedReq in
                    updateRequest(updatedReq)
                }
            }
        }
    }

    // MARK: Header

    private var doctorHeader: some View {
        HStack(spacing: 12) {
            Button { withAnimation { appState.showDrawer = true } } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.title3.weight(.medium)).foregroundStyle(AppTheme.textPrimary)
            }
            Spacer()
            VStack(alignment: isArabic ? .trailing : .leading, spacing: 4) {
                Text(isArabic
                     ? "مرحباً دكتور، \(doctorDisplayName) 👨‍⚕️"
                     : "Добро пожаловать, Доктор \(doctorDisplayName) 👨‍⚕️")
                    .font(.title3.weight(.bold)).foregroundStyle(AppTheme.textPrimary)
                Text(isArabic ? "لديك \(pendingCount) طلب جديد" : "У вас \(pendingCount) новых запросов")
                    .font(.subheadline).foregroundStyle(AppTheme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: isArabic ? .trailing : .leading)

            ZStack {
                Circle().fill(AppTheme.primarySoft).frame(width: 46, height: 46)
                Image(systemName: "bell.fill").foregroundStyle(AppTheme.primary)
                if pendingCount > 0 {
                    Circle().fill(AppTheme.danger).frame(width: 18, height: 18)
                        .overlay(Text("\(pendingCount)").font(.system(size: 10, weight: .bold)).foregroundStyle(.white))
                        .offset(x: 14, y: -14)
                }
            }
        }
        .padding(.top, 8)
    }

    private var doctorDisplayName: String {
        appState.userProfile.name.isEmpty ? (isArabic ? "محمد" : "Доктор") : appState.userProfile.name
    }

    private var pendingCount: Int { requests.filter { $0.status == .pending }.count }

    // MARK: Stats

    private var statsStrip: some View {
        HStack(spacing: 12) {
            statCard(value: "\(requests.filter{$0.status == .pending}.count)",
                     label: isArabic ? "طلبات جديدة" : "Новых",
                     color: Color(red: 0.95, green: 0.70, blue: 0.25))
            statCard(value: "\(requests.filter{$0.status == .accepted}.count)",
                     label: isArabic ? "مقبولة" : "Принято",
                     color: AppTheme.success)
            statCard(value: "\(requests.count)",
                     label: isArabic ? "إجمالي" : "Всего",
                     color: AppTheme.primary)
        }
    }

    private func statCard(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(value).font(.title2.weight(.bold)).foregroundStyle(color)
            Text(label).font(.caption2).foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 16)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: color.opacity(0.1), radius: 6)
    }

    // MARK: Requests

    private var requestsSection: some View {
        VStack(alignment: isArabic ? .trailing : .leading, spacing: 12) {
            Text(Loc.patientRequests)
                .font(.headline).foregroundStyle(AppTheme.textPrimary)

            ForEach(requests) { req in
                PatientRequestCard(request: req,
                    onAccept: { updateStatus(req, .accepted) },
                    onReject: { updateStatus(req, .rejected) },
                    onDetails: { selectedRequest = req }
                )
            }
        }
    }

    private func updateStatus(_ req: PatientRequest, _ status: RequestStatus) {
        if let i = requests.firstIndex(where: { $0.id == req.id }) {
            requests[i].status = status
        }
    }

    private func updateRequest(_ req: PatientRequest) {
        if let i = requests.firstIndex(where: { $0.id == req.id }) {
            requests[i] = req
        }
    }
}

// MARK: - Patient Request Card

struct PatientRequestCard: View {
    let request: PatientRequest
    let onAccept: () -> Void
    let onReject: () -> Void
    let onDetails: () -> Void

    private var isArabic: Bool { Loc.lang == .arabic }

    var body: some View {
        VStack(spacing: 14) {
            patientRow
            Rectangle().fill(AppTheme.bg).frame(height: 1)
            symptomRow
            if request.status == .pending { actionButtons }
            else { statusBadge }
        }
        .padding(16)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.04), radius: 8)
    }

    private var patientRow: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(request.avatarColor.opacity(0.2)).frame(width: 48, height: 48)
                Text(request.initials).font(.headline.weight(.bold)).foregroundStyle(request.avatarColor)
            }
            VStack(alignment: isArabic ? .trailing : .leading, spacing: 3) {
                Text(request.displayName).font(.subheadline.weight(.bold))
                Label(request.displayDate + " · " + request.requestedTime,
                      systemImage: "clock.fill")
                    .font(.caption).foregroundStyle(AppTheme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: isArabic ? .trailing : .leading)
        }
    }

    private var symptomRow: some View {
        VStack(alignment: isArabic ? .trailing : .leading, spacing: 4) {
            Text(isArabic ? "الأعراض:" : "Симптомы:")
                .font(.caption.weight(.semibold)).foregroundStyle(AppTheme.textSecondary)
            Text(request.displaySymptoms)
                .font(.caption).foregroundStyle(AppTheme.textPrimary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: isArabic ? .trailing : .leading)
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 10) {
            Button(action: onReject) {
                Text(Loc.reject).font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.danger)
                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                    .background(AppTheme.danger.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            Button(action: onDetails) {
                Text(Loc.viewDetails).font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.primary)
                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                    .background(AppTheme.primarySoft)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            Button(action: onAccept) {
                Text(Loc.accept).font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                    .background(AppTheme.success)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    private var statusBadge: some View {
        HStack {
            Spacer()
            Text(request.status.label(Loc.lang))
                .font(.caption.weight(.semibold))
                .foregroundStyle(request.status.color)
                .padding(.horizontal, 14).padding(.vertical, 6)
                .background(request.status.color.opacity(0.1))
                .clipShape(Capsule())
        }
    }
}
