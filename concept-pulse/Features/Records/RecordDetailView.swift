import SwiftUI

struct RecordDetailView: View {
    let record: MedicalRecord
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    recordHeader
                    if !record.values.isEmpty { labValuesCard }
                    summaryCard
                    disclaimerCard
                    Color.clear.frame(height: 20)
                }
                .padding(.horizontal, 16)
            }
            .background(AppTheme.bg.ignoresSafeArea())
            .navigationTitle(record.displayTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(Loc.lang == .arabic ? "إغلاق" : "Закрыть") { dismiss() }
                }
            }
        }
    }

    private var recordHeader: some View {
        HStack(spacing: 14) {
            VStack(alignment: .trailing, spacing: 4) {
                Text(record.displayTitle).font(.title3.weight(.bold))
                Text(record.displayDoctor).font(.subheadline).foregroundStyle(AppTheme.textSecondary)
                Text(record.displayDate).font(.caption).foregroundStyle(AppTheme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous).fill(record.type.color.opacity(0.15))
                Image(systemName: record.type.icon).font(.largeTitle).foregroundStyle(record.type.color)
            }
            .frame(width: 80, height: 80)
        }
        .padding(16).background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8)
        .padding(.top, 8)
    }

    private var labValuesCard: some View {
        VStack(alignment: .trailing, spacing: 12) {
            Text(Loc.lang == .arabic ? "نتائج الفحص" : "Результаты анализов")
                .font(.headline).frame(maxWidth: .infinity, alignment: .trailing)
            ForEach(record.values) { val in
                LabValueRow(value: val)
            }
        }
        .padding(16).background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8)
    }

    private var summaryCard: some View {
        VStack(alignment: .trailing, spacing: 8) {
            Text(Loc.lang == .arabic ? "الملخص" : "Сводка")
                .font(.headline).frame(maxWidth: .infinity, alignment: .trailing)
            Text(record.summary)
                .font(.subheadline).foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.trailing).lineSpacing(4)
        }
        .padding(16).background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8)
    }

    private var disclaimerCard: some View {
        HStack(spacing: 10) {
            Text(Loc.lang == .arabic
                 ? "هذه بيانات طبية موثقة. لا تغني عن استشارة طبيبك."
                 : "Это задокументированные медданные. Не заменяют консультацию врача.")
                .font(.caption).foregroundStyle(AppTheme.warning)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(AppTheme.warning)
        }
        .padding(14)
        .background(AppTheme.warning.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct LabValueRow: View {
    let value: LabValue

    var body: some View {
        HStack(spacing: 12) {
            if value.isAbnormal {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.caption).foregroundStyle(AppTheme.danger)
            }
            VStack(alignment: .trailing, spacing: 2) {
                Text(value.normalRange).font(.caption2).foregroundStyle(AppTheme.textSecondary)
                Text(Loc.lang == .arabic ? "المعدل الطبيعي" : "Норма")
                    .font(.system(size: 9)).foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
            Text("\(value.value) \(value.unit)")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(value.isAbnormal ? AppTheme.danger : AppTheme.textPrimary)
            Text(value.name).font(.subheadline).foregroundStyle(AppTheme.textPrimary)
        }
        .padding(.vertical, 8).padding(.horizontal, 4)
        Divider()
    }
}

// MARK: - Add Record Sheet

struct AddRecordSheet: View {
    let onSave: (MedicalRecord) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var selectedType: RecordType = .bloodTest
    @State private var notes = ""

    private let types: [RecordType] = [.bloodTest, .ecg, .prescription, .visitNote]

    var body: some View {
        NavigationStack {
            Form {
                Section(Loc.lang == .arabic ? "نوع السجل" : "Тип записи") {
                    Picker("", selection: $selectedType) {
                        ForEach(types, id: \.self) { t in
                            Label(typeName(t), systemImage: t.icon).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section(Loc.lang == .arabic ? "العنوان" : "Название") {
                    TextField(Loc.lang == .arabic ? "أدخل العنوان" : "Введите название", text: $title)
                        .multilineTextAlignment(.trailing)
                }
                Section(Loc.lang == .arabic ? "ملاحظات" : "Заметки") {
                    TextField(Loc.lang == .arabic ? "أضف ملاحظاتك..." : "Добавьте заметки...", text: $notes, axis: .vertical)
                        .lineLimit(4, reservesSpace: true)
                        .multilineTextAlignment(.trailing)
                }
            }
            .navigationTitle(Loc.addRecord)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(Loc.cancel) { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(Loc.save) {
                        guard !title.isEmpty else { return }
                        let rec = MedicalRecord(
                            type: selectedType, titleAr: title, titleRu: title,
                            dateAr: Loc.lang == .arabic ? "اليوم" : "Сегодня",
                            doctorAr: Loc.lang == .arabic ? "أضفته بنفسك" : "Добавлено вами",
                            summary: notes.isEmpty ? (Loc.lang == .arabic ? "لا توجد ملاحظات" : "Нет заметок") : notes,
                            values: [], date: Date()
                        )
                        onSave(rec)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.isEmpty)
                }
            }
        }
    }

    private func typeName(_ t: RecordType) -> String {
        switch t {
        case .bloodTest: return Loc.bloodTest
        case .ecg: return Loc.ecg
        case .prescription: return Loc.prescription
        case .visitNote: return Loc.visitNote
        case .imaging: return Loc.lang == .arabic ? "تصوير" : "Снимок"
        }
    }
}
