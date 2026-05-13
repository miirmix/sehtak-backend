import SwiftUI

struct HomeView: View {
    @State private var searchText: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    HomeHeader()
                    SearchBar(text: $searchText)
                    HealthSummaryCard()
                    UpcomingAppointmentCard(appointment: SampleData.nextAppointment)
                    SpecialtiesSection(items: SampleData.specialties)
                    AIToolsSection()
                    MedicationsSection(meds: SampleData.medications)
                    TopDoctorsSection(doctors: SampleData.doctors)
                    Color.clear.frame(height: 8)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(AppTheme.bg.ignoresSafeArea())
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Header

private struct HomeHeader: View {
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(L.greeting)، محمد 👋")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(L.howAreYou)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)

            ZStack {
                Circle().fill(AppTheme.primarySoft).frame(width: 46, height: 46)
                Image(systemName: "bell.fill")
                    .foregroundStyle(AppTheme.primary)
                Circle().fill(AppTheme.accent)
                    .frame(width: 10, height: 10)
                    .offset(x: 14, y: -14)
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - Search

private struct SearchBar: View {
    @Binding var text: String
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppTheme.textSecondary)
            TextField(L.search, text: $text)
                .font(.body)
                .multilineTextAlignment(.trailing)
            Image(systemName: "slider.horizontal.3")
                .foregroundStyle(AppTheme.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Health summary hero

private struct HealthSummaryCard: View {
    var body: some View {
        ZStack(alignment: .topTrailing) {
            AppTheme.gradient
            decoration
            content
        }
        .frame(height: 160)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: AppTheme.primary.opacity(0.25), radius: 14, x: 0, y: 8)
    }

    private var decoration: some View {
        ZStack {
            Circle().fill(Color.white.opacity(0.12))
                .frame(width: 180, height: 180).offset(x: -80, y: -90)
            Circle().fill(Color.white.opacity(0.08))
                .frame(width: 120, height: 120).offset(x: 100, y: 70)
        }
    }

    private var content: some View {
        HStack(alignment: .top) {
            VStack(alignment: .trailing, spacing: 10) {
                Text("ملخص صحتك")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.85))
                Text("ممتاز 💚")
                    .font(.title.weight(.bold))
                    .foregroundStyle(.white)
                statRow
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(20)
    }

    private var statRow: some View {
        HStack(spacing: 10) {
            statPill(icon: "heart.fill", value: "٧٢", unit: "نبضة")
            statPill(icon: "drop.fill", value: "١١٠/٧٠", unit: "ضغط")
            statPill(icon: "figure.walk", value: "٦٫٢ك", unit: "خطوة")
        }
    }

    private func statPill(icon: String, value: String, unit: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.caption).foregroundStyle(.white)
            VStack(alignment: .trailing, spacing: 0) {
                Text(value).font(.caption.weight(.bold)).foregroundStyle(.white)
                Text(unit).font(.system(size: 10)).foregroundStyle(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(Color.white.opacity(0.18))
        .clipShape(Capsule())
    }
}

// MARK: - Upcoming appointment

private struct UpcomingAppointmentCard: View {
    let appointment: Appointment

    var body: some View {
        VStack(alignment: .trailing, spacing: 14) {
            header
            divider
            doctorRow
            actionRow
        }
        .padding(18)
        .background(AppTheme.card)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AppTheme.primarySoft, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
    }

    private var header: some View {
        HStack {
            Text(L.upcoming)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .trailing)
            Label("بعد يومين", systemImage: "clock.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.primary)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(AppTheme.primarySoft)
                .clipShape(Capsule())
        }
    }

    private var divider: some View {
        Rectangle().fill(AppTheme.primarySoft).frame(height: 1)
    }

    private var doctorRow: some View {
        HStack(spacing: 12) {
            VStack(alignment: .trailing, spacing: 4) {
                Text(appointment.doctor.nameAr).font(.subheadline.weight(.bold))
                Text(appointment.doctor.specialtyAr)
                    .font(.caption).foregroundStyle(AppTheme.textSecondary)
                Label(appointment.locationAr, systemImage: "mappin.circle.fill")
                    .font(.caption2).foregroundStyle(AppTheme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)

            ZStack {
                Circle().fill(appointment.doctor.avatarColor.opacity(0.18))
                Text(appointment.doctor.initials)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(appointment.doctor.avatarColor)
            }
            .frame(width: 52, height: 52)
        }
    }

    private var actionRow: some View {
        HStack(spacing: 10) {
            actionButton(icon: "calendar", text: appointment.dateAr)
            actionButton(icon: "clock", text: appointment.timeAr)
        }
    }

    private func actionButton(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.caption)
            Text(text).font(.caption.weight(.medium))
        }
        .foregroundStyle(AppTheme.primary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(AppTheme.primarySoft.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
