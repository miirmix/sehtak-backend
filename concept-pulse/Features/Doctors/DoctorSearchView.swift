import SwiftUI

struct DoctorSearchView: View {
    @State private var searchText = ""
    @State private var selectedSpecialty: String? = nil
    @State private var selectedDoctor: DoctorDetail? = nil
    @Environment(\.dismiss) private var dismiss

    private let specialties = ["قلب", "أطفال", "أسنان", "جلدية", "باطنة", "نفسي"]

    private var filtered: [DoctorDetail] {
        var list = SampleData.doctorDetails
        if let sp = selectedSpecialty { list = list.filter { $0.specialtyKey == sp } }
        if !searchText.isEmpty {
            list = list.filter {
                $0.nameAr.contains(searchText) || $0.specialtyAr.contains(searchText) ||
                $0.nameRu.localizedCaseInsensitiveContains(searchText) ||
                $0.specialtyRu.localizedCaseInsensitiveContains(searchText) ||
                searchText.isEmpty
            }
        }
        return list
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                specialtyFilters
                doctorList
            }
            .background(AppTheme.bg.ignoresSafeArea())
            .navigationTitle(Loc.lang == .arabic ? "البحث عن طبيب" : "Поиск врача")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(item: $selectedDoctor) { doc in
                DoctorProfileView(doctor: doc)
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundStyle(AppTheme.textSecondary)
            TextField(Loc.search, text: $searchText)
                .font(.body)
                .multilineTextAlignment(Loc.lang.isRTL ? .trailing : .leading)
        }
        .padding(.horizontal, 16).padding(.vertical, 13)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 6)
        .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 8)
    }

    private var specialtyFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                filterChip(
                    title: Loc.lang == .arabic ? "الكل" : "Все",
                    selected: selectedSpecialty == nil
                ) { selectedSpecialty = nil }
                ForEach(specialties, id: \.self) { sp in
                    filterChip(title: sp, selected: selectedSpecialty == sp) {
                        selectedSpecialty = selectedSpecialty == sp ? nil : sp
                    }
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 8)
            .environment(\.layoutDirection, .rightToLeft)
        }
    }

    private func filterChip(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(selected ? .white : AppTheme.textPrimary)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(selected ? AppTheme.primary : AppTheme.card)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.04), radius: 4)
        }
    }

    private var doctorList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filtered) { doc in
                    Button { selectedDoctor = doc } label: {
                        SearchDoctorCard(doctor: doc)
                    }
                    .buttonStyle(.plain)
                }
                if filtered.isEmpty {
                    emptyState
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 8)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40)).foregroundStyle(AppTheme.textSecondary)
            Text(Loc.lang == .arabic ? "لا توجد نتائج" : "Нет результатов")
                .font(.headline).foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity).padding(40)
    }
}

struct SearchDoctorCard: View {
    let doctor: DoctorDetail

    var body: some View {
        HStack(spacing: 12) {
            avatar
            VStack(alignment: .trailing, spacing: 4) {
                Text(doctor.displayName).font(.subheadline.weight(.bold))
                Text(doctor.displaySpecialty).font(.caption).foregroundStyle(AppTheme.textSecondary)
                HStack(spacing: 8) {
                    ratingBadge
                    Text("•").font(.caption2).foregroundStyle(AppTheme.textSecondary)
                    Text(doctor.displayCity).font(.caption2).foregroundStyle(AppTheme.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            bookSection
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
    }

    private var avatar: some View {
        ZStack {
            Circle().fill(doctor.avatarColor.opacity(0.18))
            Text(doctor.initials).font(.headline.weight(.bold)).foregroundStyle(doctor.avatarColor)
        }
        .frame(width: 56, height: 56)
    }

    private var ratingBadge: some View {
        HStack(spacing: 3) {
            Image(systemName: "star.fill").font(.caption2).foregroundStyle(AppTheme.warning)
            Text(String(format: "%.1f", doctor.rating)).font(.caption.weight(.semibold))
        }
    }

    private var bookSection: some View {
        VStack(spacing: 6) {
            Text(Loc.bookNow)
                .font(.caption.weight(.bold)).foregroundStyle(.white)
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(AppTheme.primary).clipShape(Capsule())
            Text(doctor.nextSlotAr).font(.system(size: 10)).foregroundStyle(AppTheme.textSecondary)
        }
    }
}
