import SwiftUI

// MARK: - Loyalty Points Screen

struct LoyaltyPointsView: View {
    private var isArabic: Bool { Loc.lang == .arabic }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    pointsCard
                    transactionsList
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(AppTheme.bg.ignoresSafeArea())
            .navigationTitle(Loc.loyaltyPoints)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var pointsCard: some View {
        ZStack {
            AppTheme.gradient
            VStack(spacing: 8) {
                Text(isArabic ? "رصيد نقاطك" : "Ваш баланс").font(.subheadline).foregroundStyle(.white.opacity(0.85))
                Text("١٢٥٠").font(.system(size: 54, weight: .bold)).foregroundStyle(.white)
                Text(isArabic ? "نقطة" : "баллов").font(.title3).foregroundStyle(.white.opacity(0.85))
            }
        }
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: AppTheme.primary.opacity(0.3), radius: 14)
    }

    private var transactionsList: some View {
        VStack(alignment: isArabic ? .trailing : .leading, spacing: 10) {
            Text(isArabic ? "السجل" : "История")
                .font(.headline).foregroundStyle(AppTheme.textPrimary)
            ForEach(mockTransactions, id: \.0) { tx in
                loyaltyRow(title: tx.0, points: tx.1, date: tx.2, isEarn: tx.1 > 0)
            }
        }
    }

    private var mockTransactions: [(String, Int, String)] {
        isArabic
        ? [("حجز موعد د. أحمد", 50, "١٨ نوفمبر"), ("استشارة د. ليلى", 30, "١٥ نوفمبر"), ("تقييم الطبيب", 20, "١٠ نوفمبر"), ("استبدال نقاط", -100, "١ نوفمبر")]
        : [("Запись к Д-ру Ахмаду", 50, "18 нояб."), ("Консультация Д-р Лейла", 30, "15 нояб."), ("Оценка врача", 20, "10 нояб."), ("Использование баллов", -100, "1 нояб.")]
    }

    private func loyaltyRow(title: String, points: Int, date: String, isEarn: Bool) -> some View {
        HStack {
            VStack(alignment: isArabic ? .trailing : .leading, spacing: 3) {
                Text(title).font(.subheadline).foregroundStyle(AppTheme.textPrimary)
                Text(date).font(.caption).foregroundStyle(AppTheme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: isArabic ? .trailing : .leading)
            Text((isEarn ? "+" : "") + "\(points)")
                .font(.headline.weight(.bold))
                .foregroundStyle(isEarn ? AppTheme.success : AppTheme.danger)
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.03), radius: 4)
    }
}

// MARK: - Invoices Screen

struct InvoicesView: View {
    private var isArabic: Bool { Loc.lang == .arabic }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(mockInvoices, id: \.id) { inv in
                        invoiceCard(inv)
                    }
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(AppTheme.bg.ignoresSafeArea())
            .navigationTitle(Loc.invoices)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private struct InvoiceItem: Identifiable {
        let id = UUID()
        let doctorAr: String; let doctorRu: String
        let dateAr: String;   let dateRu: String
        let amount: Int
        let isPaid: Bool
    }

    private var mockInvoices: [InvoiceItem] {[
        InvoiceItem(doctorAr: "د. أحمد المنصور", doctorRu: "Д-р Ахмад", dateAr: "١٨ نوفمبر", dateRu: "18 нояб.", amount: 250, isPaid: true),
        InvoiceItem(doctorAr: "د. ليلى الحارثي", doctorRu: "Д-р Лейла", dateAr: "١٥ نوفمبر", dateRu: "15 нояб.", amount: 200, isPaid: true),
        InvoiceItem(doctorAr: "د. سارة القحطاني", doctorRu: "Д-р Сара", dateAr: "١٠ نوفمبر", dateRu: "10 нояб.", amount: 220, isPaid: false)
    ]}

    private func invoiceCard(_ inv: InvoiceItem) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill((inv.isPaid ? AppTheme.success : AppTheme.warning).opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: inv.isPaid ? "checkmark.seal.fill" : "clock.fill")
                    .foregroundStyle(inv.isPaid ? AppTheme.success : AppTheme.warning)
            }
            VStack(alignment: isArabic ? .trailing : .leading, spacing: 4) {
                Text(isArabic ? inv.doctorAr : inv.doctorRu)
                    .font(.subheadline.weight(.semibold))
                Text(isArabic ? inv.dateAr : inv.dateRu)
                    .font(.caption).foregroundStyle(AppTheme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: isArabic ? .trailing : .leading)
            VStack(alignment: isArabic ? .leading : .trailing, spacing: 4) {
                Text("\(inv.amount) \(isArabic ? "ر.س" : "SAR")")
                    .font(.headline.weight(.bold)).foregroundStyle(AppTheme.textPrimary)
                Text(inv.isPaid ? (isArabic ? "مدفوع" : "Оплачено") : (isArabic ? "غير مدفوع" : "Не оплачено"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(inv.isPaid ? AppTheme.success : AppTheme.danger)
            }
        }
        .padding(16)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.04), radius: 6)
    }
}

// MARK: - Favorite Doctors Screen

struct FavoriteDoctorsView: View {
    private var isArabic: Bool { Loc.lang == .arabic }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(SampleData.doctorDetails.prefix(3)) { doc in
                        favCard(doc)
                    }
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(AppTheme.bg.ignoresSafeArea())
            .navigationTitle(Loc.favDoctors)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func favCard(_ doc: DoctorDetail) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(doc.avatarColor.opacity(0.18)).frame(width: 52, height: 52)
                Text(doc.initials).font(.headline.weight(.bold)).foregroundStyle(doc.avatarColor)
            }
            VStack(alignment: isArabic ? .trailing : .leading, spacing: 4) {
                Text(doc.displayName).font(.subheadline.weight(.bold))
                Text(doc.displaySpecialty).font(.caption).foregroundStyle(AppTheme.primary)
                HStack(spacing: 4) {
                    Image(systemName: "star.fill").font(.caption2).foregroundStyle(AppTheme.warning)
                    Text(String(format: "%.1f", doc.rating)).font(.caption).foregroundStyle(AppTheme.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: isArabic ? .trailing : .leading)
            Image(systemName: "heart.fill").foregroundStyle(AppTheme.danger)
        }
        .padding(16)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.04), radius: 6)
    }
}
