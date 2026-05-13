import SwiftUI

struct BookingConfirmView: View {
    let doctor: DoctorDetail
    let day: AvailableDay
    let slot: String
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @State private var isConfirmed = false
    @State private var note = ""

    var body: some View {
        NavigationStack {
            if isConfirmed {
                SuccessView(doctorName: doctor.displayName) {
                    dismiss()
                }
            } else {
                confirmContent
            }
        }
    }

    private var confirmContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                summaryHeader
                detailsCard
                feeCard
                noteField
                confirmButton
                Color.clear.frame(height: 20)
            }
            .padding(.horizontal, 16)
        }
        .background(AppTheme.bg.ignoresSafeArea())
        .navigationTitle(Loc.lang == .arabic ? "تأكيد الحجز" : "Подтверждение")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(Loc.cancel) { dismiss() }
                    .foregroundStyle(AppTheme.danger)
            }
        }
    }

    private var summaryHeader: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle().fill(doctor.avatarColor.opacity(0.18)).frame(width: 80, height: 80)
                Text(doctor.initials).font(.title.weight(.bold)).foregroundStyle(doctor.avatarColor)
            }
            Text(doctor.displayName).font(.title3.weight(.bold))
            Text(doctor.displaySpecialty).font(.subheadline).foregroundStyle(AppTheme.textSecondary)
        }
        .padding(.top, 12)
    }

    private var detailsCard: some View {
        VStack(spacing: 0) {
            detailRow(icon: "calendar", label: Loc.lang == .arabic ? "التاريخ" : "Дата",
                      value: day.displayDate)
            Divider().padding(.horizontal)
            detailRow(icon: "clock", label: Loc.lang == .arabic ? "الوقت" : "Время", value: slot)
            Divider().padding(.horizontal)
            detailRow(icon: "mappin.circle.fill", label: Loc.lang == .arabic ? "العنوان" : "Адрес",
                      value: doctor.addressAr)
        }
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8)
    }

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .trailing, spacing: 2) {
                Text(label).font(.caption).foregroundStyle(AppTheme.textSecondary)
                Text(value).font(.subheadline.weight(.semibold))
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            Image(systemName: icon).foregroundStyle(AppTheme.primary).frame(width: 28)
        }
        .padding(14)
    }

    private var feeCard: some View {
        HStack {
            Text("\(doctor.consultationFee) \(Loc.lang == .arabic ? "ريال سعودي" : "SAR")")
                .font(.title3.weight(.bold)).foregroundStyle(AppTheme.primary)
            Spacer()
            Text(Loc.consultationFee).font(.subheadline).foregroundStyle(AppTheme.textSecondary)
        }
        .padding(16)
        .background(AppTheme.primarySoft.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var noteField: some View {
        VStack(alignment: .trailing, spacing: 8) {
            Text(Loc.lang == .arabic ? "ملاحظة (اختياري)" : "Примечание (необязательно)")
                .font(.caption).foregroundStyle(AppTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
            TextField(Loc.lang == .arabic ? "أضف ملاحظة للطبيب..." : "Добавить заметку врачу...", text: $note, axis: .vertical)
                .font(.subheadline)
                .multilineTextAlignment(.trailing)
                .lineLimit(3, reservesSpace: true)
                .padding(12)
                .background(AppTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: .black.opacity(0.04), radius: 6)
        }
    }

    private var confirmButton: some View {
        Button {
            let appt = Appointment(
                doctor: Doctor(nameAr: doctor.nameAr, nameRu: doctor.nameRu,
                               specialtyAr: doctor.specialtyAr, specialtyRu: doctor.specialtyRu,
                               cityAr: doctor.cityAr, cityRu: doctor.cityRu,
                               rating: doctor.rating, reviews: doctor.reviews, yearsExp: doctor.yearsExp,
                               nextSlotAr: slot, nextSlotRu: slot,
                               avatarColor: doctor.avatarColor, initials: doctor.initials),
                dateAr: day.dateAr, dateRu: day.dateRu, timeAr: slot, timeRu: slot,
                locationAr: doctor.addressAr, locationRu: doctor.addressAr, isUpcoming: true
            )
            appState.addAppointment(appt)
            withAnimation { isConfirmed = true }
        } label: {
            Text(Loc.confirm)
                .font(.body.weight(.bold)).foregroundStyle(.white)
                .frame(maxWidth: .infinity).padding(.vertical, 16)
                .background(AppTheme.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: AppTheme.primary.opacity(0.3), radius: 10)
        }
    }
}

// MARK: - Success Screen

struct SuccessView: View {
    let doctorName: String
    let onDone: () -> Void
    @State private var scale: CGFloat = 0.5

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle().fill(AppTheme.success.opacity(0.15)).frame(width: 130, height: 130)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 70)).foregroundStyle(AppTheme.success)
            }
            .scaleEffect(scale)
            .onAppear { withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { scale = 1.0 } }
            Text(Loc.bookingSuccess).font(.title2.weight(.bold))
            VStack(spacing: 6) {
                Text(Loc.lang == .arabic ? "تم تأكيد موعدك مع" : "Ваша запись к врачу подтверждена")
                    .font(.subheadline).foregroundStyle(AppTheme.textSecondary)
                Text(doctorName).font(.subheadline.weight(.semibold))
            }
            Text(Loc.lang == .arabic ? "ستجد الموعد في قسم مواعيدي" : "Запись добавлена в раздел «Записи»")
                .font(.caption).foregroundStyle(AppTheme.textSecondary)
                .padding(.horizontal, 32).multilineTextAlignment(.center)
            Spacer()
            Button(action: onDone) {
                Text(Loc.lang == .arabic ? "العودة للرئيسية" : "На главную")
                    .font(.body.weight(.bold)).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(AppTheme.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .padding(.horizontal, 24).padding(.bottom, 32)
        }
        .background(AppTheme.bg.ignoresSafeArea())
    }
}
