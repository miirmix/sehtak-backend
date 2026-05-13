import SwiftUI

struct AppointmentsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var tab: Int = 0
    @State private var cancelTarget: Appointment? = nil
    @State private var showCancelAlert = false

    private var upcoming: [Appointment] { appState.appointments.filter { $0.isUpcoming } }
    private var past: [Appointment]     { appState.appointments.filter { !$0.isUpcoming } }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                tabSegment
                ScrollView {
                    LazyVStack(spacing: 14) {
                        let list = tab == 0 ? upcoming : past
                        if list.isEmpty { emptyState }
                        ForEach(list) { appt in
                            AppointmentCard(appt: appt) {
                                cancelTarget = appt
                                showCancelAlert = true
                            }
                        }
                        Color.clear.frame(height: 20)
                    }
                    .padding(.horizontal, 16).padding(.top, 16)
                }
            }
            .background(AppTheme.bg.ignoresSafeArea())
            .navigationTitle(Loc.appointments)
            .navigationBarTitleDisplayMode(.inline)
            .alert(Loc.cancelAppt, isPresented: $showCancelAlert, presenting: cancelTarget) { appt in
                Button(Loc.cancel, role: .destructive) {
                    withAnimation { appState.cancelAppointment(appt.id) }
                }
                Button(Loc.lang == .arabic ? "تراجع" : "Назад", role: .cancel) {}
            } message: { _ in
                Text(Loc.cancelConfirm)
            }
        }
    }

    private var tabSegment: some View {
        HStack(spacing: 0) {
            tabButton(title: Loc.upcoming, index: 0)
            tabButton(title: Loc.past, index: 1)
        }
        .padding(4)
        .background(AppTheme.primarySoft.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 20).padding(.vertical, 12)
    }

    private func tabButton(title: String, index: Int) -> some View {
        Button { withAnimation(.spring(response: 0.3)) { tab = index } } label: {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tab == index ? .white : AppTheme.textSecondary)
                .frame(maxWidth: .infinity).padding(.vertical, 10)
                .background(tab == index ? AppTheme.primary : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 50, weight: .light)).foregroundStyle(AppTheme.textSecondary.opacity(0.4))
            Text(tab == 0 ? (Loc.lang == .arabic ? "لا مواعيد قادمة" : "Нет предстоящих записей")
                          : (Loc.lang == .arabic ? "لا مواعيد سابقة" : "Нет прошедших записей"))
                .font(.subheadline).foregroundStyle(AppTheme.textSecondary)
        }
        .padding(50)
    }
}

struct AppointmentCard: View {
    let appt: Appointment
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            header
            Divider().padding(.horizontal, 14)
            doctorRow
            if appt.isUpcoming { actionRow }
        }
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)
    }

    private var header: some View {
        HStack {
            statusBadge
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(appt.dateAr).font(.caption.weight(.semibold))
                Text(appt.timeAr).font(.caption2).foregroundStyle(AppTheme.textSecondary)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
    }

    private var statusBadge: some View {
        Text(appt.displayStatus)
            .font(.caption2.weight(.bold))
            .foregroundStyle(appt.isUpcoming ? AppTheme.success : AppTheme.textSecondary)
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background((appt.isUpcoming ? AppTheme.success : AppTheme.textSecondary).opacity(0.12))
            .clipShape(Capsule())
    }

    private var doctorRow: some View {
        HStack(spacing: 12) {
            VStack(alignment: .trailing, spacing: 4) {
                Text(appt.doctor.nameAr).font(.subheadline.weight(.bold))
                Text(appt.doctor.specialtyAr).font(.caption).foregroundStyle(AppTheme.textSecondary)
                Label(appt.locationAr, systemImage: "mappin.circle.fill")
                    .font(.caption2).foregroundStyle(AppTheme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            ZStack {
                Circle().fill(appt.doctor.avatarColor.opacity(0.18))
                Text(appt.doctor.initials).font(.subheadline.weight(.bold)).foregroundStyle(appt.doctor.avatarColor)
            }
            .frame(width: 52, height: 52)
        }
        .padding(14)
    }

    private var actionRow: some View {
        HStack(spacing: 10) {
            Button(action: onCancel) {
                Text(Loc.cancelAppt)
                    .font(.caption.weight(.semibold)).foregroundStyle(AppTheme.danger)
                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                    .background(AppTheme.danger.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            Button {} label: {
                Text(Loc.lang == .arabic ? "إعادة جدولة" : "Перенести")
                    .font(.caption.weight(.semibold)).foregroundStyle(AppTheme.primary)
                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                    .background(AppTheme.primarySoft.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .padding(.horizontal, 14).padding(.bottom, 12)
    }
}
