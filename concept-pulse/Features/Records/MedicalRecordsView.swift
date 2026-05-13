import SwiftUI

struct MedicalRecordsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedRecord: MedicalRecord? = nil
    @State private var showAddSheet = false

    private let filterTypes: [RecordType?] = [nil, .bloodTest, .ecg, .prescription, .visitNote]
    @State private var filterType: RecordType? = nil

    private var filtered: [MedicalRecord] {
        guard let ft = filterType else { return appState.medicalRecords }
        return appState.medicalRecords.filter { $0.type == ft }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                patientBanner
                typeFilter
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filtered) { rec in
                            Button { selectedRecord = rec } label: {
                                RecordRow(record: rec)
                            }
                            .buttonStyle(.plain)
                        }
                        Color.clear.frame(height: 24)
                    }
                    .padding(.horizontal, 16).padding(.top, 12)
                }
            }
            .background(AppTheme.bg.ignoresSafeArea())
            .navigationTitle(Loc.medicalFile)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { showAddSheet = true } label: {
                        Label(Loc.addRecord, systemImage: "plus.circle.fill")
                            .font(.subheadline.weight(.semibold))
                    }
                }
            }
            .sheet(item: $selectedRecord) { rec in
                RecordDetailView(record: rec)
            }
            .sheet(isPresented: $showAddSheet) {
                AddRecordSheet { rec in appState.medicalRecords.insert(rec, at: 0) }
            }
        }
    }

    private var patientBanner: some View {
        HStack(spacing: 14) {
            VStack(alignment: .trailing, spacing: 4) {
                Text(appState.userProfile.name.isEmpty ? L("محمد أحمد", "Мухаммад Ахмад") : appState.userProfile.name)
                    .font(.subheadline.weight(.bold))
                HStack(spacing: 8) {
                    Text(L("٣٥ سنة", "35 лет")).font(.caption).foregroundStyle(AppTheme.textSecondary)
                    Text("•").font(.caption2).foregroundStyle(AppTheme.textSecondary)
                    Text(L("فصيلة الدم: B+", "Группа крови: B+"))
                        .font(.caption).foregroundStyle(AppTheme.primary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            ZStack {
                Circle().fill(AppTheme.primary.opacity(0.15)).frame(width: 50, height: 50)
                Image(systemName: "person.fill").font(.title3).foregroundStyle(AppTheme.primary)
            }
        }
        .padding(16)
        .background(AppTheme.card)
        .shadow(color: .black.opacity(0.04), radius: 6)
    }

    private var typeFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                filterChip(type: nil, label: Loc.lang == .arabic ? "الكل" : "Все")
                filterChip(type: .bloodTest, label: Loc.bloodTest)
                filterChip(type: .ecg, label: Loc.ecg)
                filterChip(type: .prescription, label: Loc.prescription)
                filterChip(type: .visitNote, label: Loc.visitNote)
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
            .environment(\.layoutDirection, .rightToLeft)
        }
    }

    private func filterChip(type: RecordType?, label: String) -> some View {
        Button { withAnimation { filterType = type } } label: {
            HStack(spacing: 6) {
                if let t = type { Image(systemName: t.icon).font(.caption2) }
                Text(label).font(.caption.weight(.semibold))
            }
            .foregroundStyle(filterType == type ? .white : AppTheme.textPrimary)
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background(filterType == type ? AppTheme.primary : AppTheme.card)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.04), radius: 4)
        }
    }
}

struct RecordRow: View {
    let record: MedicalRecord

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .trailing, spacing: 4) {
                Text(record.displayTitle).font(.subheadline.weight(.semibold))
                Text(record.displayDoctor).font(.caption).foregroundStyle(AppTheme.textSecondary)
                Text(record.displayDate).font(.caption2).foregroundStyle(AppTheme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous).fill(record.type.color.opacity(0.15))
                Image(systemName: record.type.icon).font(.title3).foregroundStyle(record.type.color)
            }
            .frame(width: 52, height: 52)
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 6)
    }
}
