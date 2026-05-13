import SwiftUI

// MARK: - Specialties

struct SpecialtiesSection: View {
    let items: [Specialty]
    var onTap: ((Specialty) -> Void)? = nil

    var body: some View {
        VStack(alignment: .trailing, spacing: 12) {
            SectionHeader(title: L.specialties)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(items) { item in
                        Button { onTap?(item) } label: { SpecialtyChip(item: item) }
                            .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
                .environment(\.layoutDirection, .rightToLeft)
            }
        }
    }
}

private struct SpecialtyChip: View {
    let item: Specialty
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(item.color.opacity(0.15))
                Image(systemName: item.icon)
                    .font(.title3)
                    .foregroundStyle(item.color)
            }
            .frame(width: 60, height: 60)
            Text(item.displayName)
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.textPrimary)
        }
        .frame(width: 76)
    }
}

// MARK: - AI Tools

struct AIToolsSection: View {
    var body: some View {
        VStack(alignment: .trailing, spacing: 12) {
            SectionHeader(title: L.aiTools, trailingIcon: "sparkles")
            HStack(spacing: 12) {
                AIToolCard(
                    title: L.aiChat,
                    subtitle: L.aiChatDesc,
                    icon: "message.fill",
                    gradient: LinearGradient(
                        colors: [Color(red: 0.45, green: 0.40, blue: 0.85),
                                 Color(red: 0.65, green: 0.45, blue: 0.95)],
                        startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                AIToolCard(
                    title: L.aiImage,
                    subtitle: L.aiImageDesc,
                    icon: "photo.on.rectangle.angled",
                    gradient: LinearGradient(
                        colors: [Color(red: 0.95, green: 0.55, blue: 0.45),
                                 Color(red: 0.98, green: 0.70, blue: 0.50)],
                        startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            }
        }
    }
}

private struct AIToolCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let gradient: LinearGradient

    var body: some View {
        VStack(alignment: .trailing, spacing: 10) {
            ZStack {
                Circle().fill(Color.white.opacity(0.22))
                Image(systemName: icon).font(.title3).foregroundStyle(.white)
            }
            .frame(width: 40, height: 40)

            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(2)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 130, alignment: .topTrailing)
        .background(gradient)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.10), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Medications

struct MedicationsSection: View {
    let meds: [Medication]

    var body: some View {
        VStack(alignment: .trailing, spacing: 12) {
            SectionHeader(title: L.medications, trailingIcon: "pills.fill")
            VStack(spacing: 10) {
                ForEach(meds) { med in
                    MedicationRow(med: med)
                }
            }
        }
    }
}

private struct MedicationRow: View {
    let med: Medication

    var body: some View {
        HStack(spacing: 12) {
            checkmark
            VStack(alignment: .trailing, spacing: 3) {
                Text(med.displayName).font(.subheadline.weight(.semibold))
                Text("\(med.displayDose) • \(med.displayTime)")
                    .font(.caption).foregroundStyle(AppTheme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)

            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppTheme.primarySoft.opacity(0.5))
                Image(systemName: "pills.fill")
                    .foregroundStyle(AppTheme.primary)
            }
            .frame(width: 44, height: 44)
        }
        .padding(12)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
    }

    private var checkmark: some View {
        ZStack {
            Circle()
                .stroke(med.taken ? AppTheme.success : Color.gray.opacity(0.3), lineWidth: 2)
                .background(Circle().fill(med.taken ? AppTheme.success : Color.clear))
            if med.taken {
                Image(systemName: "checkmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: 26, height: 26)
    }
}

// MARK: - Top doctors

struct TopDoctorsSection: View {
    let doctors: [DoctorDetail]
    var onBook: ((DoctorDetail) -> Void)? = nil

    var body: some View {
        VStack(alignment: .trailing, spacing: 12) {
            SectionHeader(title: L.topDoctors, action: L.viewAll)
            VStack(spacing: 10) {
                ForEach(doctors.prefix(4)) { d in
                    Button { onBook?(d) } label: { DoctorCard(doctor: d) }
                        .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct DoctorCard: View {
    let doctor: DoctorDetail

    var body: some View {
        HStack(spacing: 12) {
            avatar
            VStack(alignment: .trailing, spacing: 4) {
                Text(doctor.displayName).font(.subheadline.weight(.bold))
                Text(doctor.displaySpecialty).font(.caption).foregroundStyle(AppTheme.textSecondary)
                ratingRow
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            bookButton
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
    }

    private var avatar: some View {
        ZStack {
            Circle().fill(doctor.avatarColor.opacity(0.18))
            Text(doctor.initials).font(.headline.weight(.bold)).foregroundStyle(doctor.avatarColor)
        }
        .frame(width: 56, height: 56)
    }

    private var ratingRow: some View {
        HStack(spacing: 8) {
            HStack(spacing: 3) {
                Image(systemName: "star.fill").font(.caption2).foregroundStyle(AppTheme.warning)
                Text(String(format: "%.1f", doctor.rating)).font(.caption.weight(.semibold))
            }
            Text("•").font(.caption2).foregroundStyle(AppTheme.textSecondary)
            Text(doctor.displayCity).font(.caption2).foregroundStyle(AppTheme.textSecondary)
        }
    }

    private var bookButton: some View {
        VStack(spacing: 6) {
            Text(L.bookNow)
                .font(.caption.weight(.bold)).foregroundStyle(.white)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(AppTheme.primary).clipShape(Capsule())
            Text(doctor.displayName == doctor.nameAr ? doctor.nextSlotAr : L(doctor.nextSlotAr, doctor.nextSlotAr))
                .font(.system(size: 10)).foregroundStyle(AppTheme.textSecondary)
        }
    }
}

// MARK: - Section header

struct SectionHeader: View {
    let title: String
    var trailingIcon: String? = nil
    var action: String? = nil

    var body: some View {
        HStack {
            if let action {
                Text(action)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.primary)
            }
            Spacer()
            HStack(spacing: 6) {
                Text(title).font(.headline)
                if let trailingIcon {
                    Image(systemName: trailingIcon)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.primary)
                }
            }
        }
    }
}
