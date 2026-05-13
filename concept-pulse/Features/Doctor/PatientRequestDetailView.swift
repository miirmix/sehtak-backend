import SwiftUI

struct PatientRequestDetailView: View {
    @State var request: PatientRequest
    let onUpdate: (PatientRequest) -> Void
    @Environment(\.dismiss) private var dismiss

    private var isArabic: Bool { Loc.lang == .arabic }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                patientCard
                symptomsCard
                medNotesCard
                attachmentsCard
                if request.status == .pending { actionButtons }
                else { statusDisplay }
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .background(AppTheme.bg.ignoresSafeArea())
        .navigationTitle(isArabic ? "تفاصيل الطلب" : "Детали запроса")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Patient Info

    private var patientCard: some View {
        VStack(alignment: isArabic ? .trailing : .leading, spacing: 14) {
            sectionTitle(isArabic ? "معلومات المريض" : "Данные пациента")
            HStack(spacing: 16) {
                ZStack {
                    Circle().fill(request.avatarColor.opacity(0.2)).frame(width: 64, height: 64)
                    Text(request.initials).font(.title2.weight(.bold)).foregroundStyle(request.avatarColor)
                }
                VStack(alignment: isArabic ? .trailing : .leading, spacing: 6) {
                    Text(request.displayName).font(.title3.weight(.bold))
                    Label(request.displayDate, systemImage: "calendar")
                        .font(.subheadline).foregroundStyle(AppTheme.textSecondary)
                    Label(request.requestedTime, systemImage: "clock.fill")
                        .font(.subheadline).foregroundStyle(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: isArabic ? .trailing : .leading)
            }
        }
        .padding(16)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.04), radius: 8)
    }

    // MARK: Symptoms

    private var symptomsCard: some View {
        infoCard(
            title: Loc.symptoms,
            icon: "stethoscope",
            color: AppTheme.primary,
            text: request.displaySymptoms
        )
    }

    // MARK: Med Notes

    private var medNotesCard: some View {
        infoCard(
            title: Loc.medNotes,
            icon: "note.text",
            color: Color(red: 0.95, green: 0.70, blue: 0.40),
            text: request.displayNotes
        )
    }

    // MARK: Attachments

    private var attachmentsCard: some View {
        VStack(alignment: isArabic ? .trailing : .leading, spacing: 12) {
            sectionTitle(isArabic ? "المرفقات" : "Вложения")
            HStack(spacing: 12) {
                attachmentPlaceholder(icon: "doc.fill", label: isArabic ? "نتائج التحاليل" : "Анализы")
                attachmentPlaceholder(icon: "photo.fill", label: isArabic ? "صور طبية" : "Снимки")
                attachmentPlaceholder(icon: "waveform.path.ecg", label: "ECG")
            }
        }
        .padding(16)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.04), radius: 8)
    }

    private func attachmentPlaceholder(icon: String, label: String) -> some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(AppTheme.bg).frame(width: 56, height: 56)
                Image(systemName: icon).font(.title3).foregroundStyle(AppTheme.textSecondary)
            }
            Text(label).font(.caption2).foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Actions

    private var actionButtons: some View {
        HStack(spacing: 14) {
            Button {
                request.status = .rejected
                onUpdate(request)
                dismiss()
            } label: {
                Label(Loc.reject, systemImage: "xmark.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.danger)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(AppTheme.danger.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            Button {
                request.status = .accepted
                onUpdate(request)
                dismiss()
            } label: {
                Label(Loc.accept, systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(AppTheme.success)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private var statusDisplay: some View {
        HStack {
            Spacer()
            Text(request.status.label(Loc.lang))
                .font(.headline.weight(.semibold))
                .foregroundStyle(request.status.color)
                .padding(.horizontal, 24).padding(.vertical, 12)
                .background(request.status.color.opacity(0.12))
                .clipShape(Capsule())
            Spacer()
        }
    }

    // MARK: Helpers

    private func sectionTitle(_ t: String) -> some View {
        Text(t).font(.subheadline.weight(.semibold)).foregroundStyle(AppTheme.textSecondary)
    }

    private func infoCard(title: String, icon: String, color: Color, text: String) -> some View {
        VStack(alignment: isArabic ? .trailing : .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon).foregroundStyle(color)
                Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(AppTheme.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: isArabic ? .trailing : .leading)
            Text(text).font(.body).foregroundStyle(AppTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: isArabic ? .trailing : .leading)
        }
        .padding(16)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.04), radius: 8)
    }
}
