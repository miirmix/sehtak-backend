import SwiftUI

struct DoctorProfileView: View {
    let doctor: DoctorDetail
    @State private var selectedDay: AvailableDay? = nil
    @State private var selectedSlot: String? = nil
    @State private var showBooking = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                profileHeader
                statsRow
                bioSection
                availabilitySection
                if selectedSlot != nil {
                    bookButton
                }
                Color.clear.frame(height: 20)
            }
            .padding(.horizontal, 16)
        }
        .background(AppTheme.bg.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showBooking) {
            BookingConfirmView(doctor: doctor,
                               day: selectedDay ?? doctor.availableDates[0],
                               slot: selectedSlot ?? "")
        }
    }

    // MARK: Header
    private var profileHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(doctor.avatarColor.opacity(0.18)).frame(width: 100, height: 100)
                Text(doctor.initials).font(.largeTitle.weight(.bold)).foregroundStyle(doctor.avatarColor)
            }
            Text(doctor.displayName).font(.title2.weight(.bold))
            Text(doctor.displaySpecialty).font(.subheadline).foregroundStyle(AppTheme.textSecondary)
            HStack(spacing: 6) {
                Image(systemName: "mappin.circle.fill").font(.caption).foregroundStyle(AppTheme.primary)
                Text(doctor.addressAr).font(.caption).foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 8)
    }

    // MARK: Stats
    private var statsRow: some View {
        HStack(spacing: 0) {
            statItem(value: String(format: "%.1f", doctor.rating), label: Loc.rating,
                     icon: "star.fill", color: AppTheme.warning)
            Divider().frame(height: 40)
            statItem(value: "\(doctor.yearsExp)", label: Loc.experience,
                     icon: "clock.fill", color: AppTheme.primary)
            Divider().frame(height: 40)
            statItem(value: "\(doctor.reviews)", label: Loc.reviews,
                     icon: "person.2.fill", color: AppTheme.success)
            Divider().frame(height: 40)
            statItem(value: "\(doctor.consultationFee)", label: "ريال",
                     icon: "banknote.fill", color: AppTheme.accent)
        }
        .padding(16)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8)
    }

    private func statItem(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.caption).foregroundStyle(color)
            Text(value).font(.subheadline.weight(.bold))
            Text(label).font(.system(size: 10)).foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Bio
    private var bioSection: some View {
        VStack(alignment: .trailing, spacing: 8) {
            Text(Loc.lang == .arabic ? "نبذة عن الطبيب" : "О враче")
                .font(.headline).frame(maxWidth: .infinity, alignment: .trailing)
            Text(doctor.bio)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.trailing)
                .lineSpacing(4)
        }
        .padding(16)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8)
    }

    // MARK: Availability
    private var availabilitySection: some View {
        VStack(alignment: .trailing, spacing: 14) {
            Text(Loc.availableSlots).font(.headline).frame(maxWidth: .infinity, alignment: .trailing)
            dayPicker
            if let day = selectedDay {
                slotPicker(for: day)
            }
        }
        .padding(16)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8)
    }

    private var dayPicker: some View {
        HStack(spacing: 10) {
            ForEach(doctor.availableDates) { day in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedDay = day
                        selectedSlot = nil
                    }
                } label: {
                    Text(day.displayDate)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(selectedDay?.id == day.id ? .white : AppTheme.textPrimary)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(selectedDay?.id == day.id ? AppTheme.primary : AppTheme.primarySoft.opacity(0.4))
                        .clipShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private func slotPicker(for day: AvailableDay) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
            ForEach(day.slots, id: \.self) { slot in
                Button {
                    withAnimation(.spring(response: 0.25)) { selectedSlot = slot }
                } label: {
                    Text(slot)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(selectedSlot == slot ? .white : AppTheme.primary)
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                        .background(selectedSlot == slot ? AppTheme.primary : AppTheme.primarySoft.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
    }

    // MARK: Book Button
    private var bookButton: some View {
        Button { showBooking = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "calendar.badge.checkmark")
                Text(Loc.bookNow)
            }
            .font(.body.weight(.bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity).padding(.vertical, 16)
            .background(AppTheme.gradient)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: AppTheme.primary.opacity(0.3), radius: 10, x: 0, y: 5)
        }
    }
}
