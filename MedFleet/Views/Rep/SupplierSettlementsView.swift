import SwiftUI

struct SupplierSettlementsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var connectivity: Connectivity

    private enum Tab: String, CaseIterable, Identifiable {
        case transactions = "التسديدات"
        case bySupplier = "لكل مورد"
        case monthly = "شهري"
        var id: String { rawValue }
    }

    @State private var summary: SettlementsSummary?
    @State private var loading = true
    @State private var tab: Tab = .transactions

    var body: some View {
        OpenModuleLayout(onBack: { dismiss() }) {
            VStack(spacing: 0) {
                if !connectivity.isOnline { OfflineBanner() }

                header

                Picker("", selection: $tab) {
                    ForEach(Tab.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 6)
                .padding(.bottom, 8)

                Group {
                    if loading && summary == nil {
                        ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if (summary?.grandCount ?? 0) == 0 {
                        emptyState
                    } else {
                        switch tab {
                        case .transactions: transactionsList
                        case .bySupplier: bySupplierList
                        case .monthly: monthlyList
                        }
                    }
                }
            }
        }
        .task(id: appState.settlementsRefresh) { await load() }
        .refreshable { await load() }
    }

    // MARK: - Header (grand total)

    private var header: some View {
        VStack(spacing: 2) {
            Text("إجمالي ما سدّدته")
                .font(.caption)
                .foregroundStyle(MFColors.muted)
            Text("\(MFFormat.money(summary?.grandTotal ?? 0)) د.ع")
                .font(.title.bold())
                .foregroundStyle(MFColors.ok)
            if let n = summary?.grandCount, n > 0 {
                Text("\(n) تسديدة")
                    .font(.caption2)
                    .foregroundStyle(MFColors.muted)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 44)
        .padding(.bottom, 6)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "banknote")
                .font(.system(size: 40))
                .foregroundStyle(MFColors.muted.opacity(0.5))
            Text("لا توجد تسديدات بعد")
                .foregroundStyle(MFColors.muted)
            Text("كل تسديدة تسوّيها من المواعيد تنحفظ هنا")
                .font(.caption)
                .foregroundStyle(MFColors.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Transactions grouped by day

    private var transactionsList: some View {
        List {
            ForEach(groupedByDay, id: \.day) { group in
                Section {
                    ForEach(group.items) { tx in
                        HStack {
                            Text("\(MFFormat.money(tx.amount)) د.ع")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(MFColors.ok)
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(tx.supplierName ?? "مورد")
                                    .font(.body.weight(.medium))
                                Text(timeOf(tx.settledAt))
                                    .font(.caption2)
                                    .foregroundStyle(MFColors.muted)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                } header: {
                    HStack {
                        Text("\(MFFormat.money(group.total)) د.ع")
                            .foregroundStyle(MFColors.ok)
                        Spacer()
                        Text("\(MFFormat.arabicDay(group.day)) • \(MFFormat.dueDate(group.day))")
                    }
                    .font(.caption.weight(.semibold))
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Per supplier totals

    private var bySupplierList: some View {
        List(summary?.bySupplier ?? []) { row in
            HStack {
                Text("\(MFFormat.money(row.total)) د.ع")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(MFColors.ok)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(row.supplierName ?? "مورد")
                        .font(.body.weight(.medium))
                    Text("\(row.count) تسديدة • آخر: \(MFFormat.dueDate(row.lastSettledAt))")
                        .font(.caption2)
                        .foregroundStyle(MFColors.muted)
                }
            }
            .padding(.vertical, 2)
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Monthly totals

    private var monthlyList: some View {
        List(summary?.monthly ?? []) { row in
            HStack {
                Text("\(MFFormat.money(row.total)) د.ع")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(MFColors.ok)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(monthLabel(row.month))
                        .font(.body.weight(.medium))
                    Text("\(row.count) تسديدة")
                        .font(.caption2)
                        .foregroundStyle(MFColors.muted)
                }
            }
            .padding(.vertical, 2)
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Helpers

    private struct DayGroup { let day: String; let total: Double; let items: [Settlement] }

    private var groupedByDay: [DayGroup] {
        let txs = summary?.transactions ?? []
        let groups = Dictionary(grouping: txs) { $0.day ?? String($0.settledAt.prefix(10)) }
        return groups.keys.sorted(by: >).map { key in
            let items = groups[key] ?? []
            return DayGroup(day: key, total: items.reduce(0) { $0 + $1.amount }, items: items)
        }
    }

    private func timeOf(_ iso: String) -> String {
        let f1 = ISO8601DateFormatter()
        f1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = f1.date(from: iso) ?? ISO8601DateFormatter().date(from: iso)
        guard let d = date else { return "" }
        let out = DateFormatter()
        out.locale = Locale(identifier: "ar")
        out.timeZone = TimeZone(identifier: "Asia/Baghdad")
        out.dateFormat = "h:mm a"
        return out.string(from: d)
    }

    private func monthLabel(_ ym: String) -> String {
        let inF = DateFormatter()
        inF.dateFormat = "yyyy-MM"
        guard let d = inF.date(from: ym) else { return ym }
        let out = DateFormatter()
        out.locale = Locale(identifier: "ar")
        out.dateFormat = "MMMM yyyy"
        return out.string(from: d)
    }

    private func load() async {
        guard let api = appState.api else { loading = false; return }
        if let s = try? await api.getSettlements() {
            summary = s
        }
        loading = false
    }
}
