import SwiftUI

// MARK: - المخزن

enum StockFilter: Hashable { case all, low }

/// showCost = true للمدير فقط.
struct InventoryView: View {
    let showCost: Bool
    @Environment(AppStore.self) private var store
    @Environment(Router.self) private var router
    @State private var products: [LookProduct]?
    @State private var query = ""
    @State private var filter = StockFilter.all

    private var filtered: [LookProduct] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        return (products ?? []).filter { p in
            (filter == .all || p.isLowStock) &&
                (q.isEmpty || p.name.lowercased().contains(q) ||
                    (p.generic?.lowercased().contains(q) ?? false) || (p.barcode?.contains(q) ?? false))
        }
    }

    var body: some View {
        ScreenScroll {
            PageHeader(
                title: "المخزن",
                subtitle: products.map { "\($0.count) منتج" } ?? " ",
                subtitleAbove: true,
                trailing: showCost
                    ? AnyView(CircleIconButton(systemName: "plus", label: "إضافة منتج", background: MF.pine, tint: MF.gold) {})
                    : nil
            )
            HStack(spacing: 10) {
                SearchField(hint: "ابحث بالاسم أو الباركود", text: $query)
                CircleIconButton(systemName: "barcode.viewfinder", label: "مسح باركود", size: 52, tint: MF.pine) {
                    router.push(.scanner(.barcode))
                }
            }
            .padding(.top, 18)
            FilterChips(options: [(StockFilter.all, "الكل"), (StockFilter.low, "رصيد منخفض")], value: $filter)
                .padding(.top, 14)

            Group {
                if products == nil {
                    LoadingView()
                } else if filtered.isEmpty {
                    EmptyCard(text: "لا توجد نتائج")
                } else {
                    GroupedList(filtered) { p in productRow(p) }
                }
            }
            .padding(.top, 16)
        }
        .task { products = await store.repo.products() }
    }

    private func productRow(_ p: LookProduct) -> some View {
        var parts: [String] = []
        if let g = p.generic { parts.append(g) }
        if showCost, let c = p.cost { parts.append("كلفة \(money(c))") }
        if let b = p.barcode { parts.append(b) }
        return ListRow(
            title: p.name,
            subtitle: parts.isEmpty ? nil : parts.joined(separator: " · "),
            minHeight: 72,
            leading: AnyView(IconTile(text: String(p.name.prefix(1)))),
            trailing: AnyView(
                VStack(alignment: .trailing, spacing: 4) {
                    MoneyText(value: p.sellPrice)
                    StatusPill(
                        label: p.stock.map { "الرصيد \($0)" } ?? "الرصيد —",
                        bg: p.isLowStock ? MF.warnTint : MF.mintTint,
                        fg: p.isLowStock ? MF.warnText : MF.pine
                    )
                }
            )
        )
    }
}

// MARK: - المبيعات (للمدير)

struct SessionsView: View {
    @Environment(AppStore.self) private var store
    @Environment(Router.self) private var router
    @State private var month = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date())) ?? Date()
    @State private var summary: MonthSummary?
    @State private var sessions: [LookSession] = []

    private var isCurrentMonth: Bool {
        Calendar.current.isDate(month, equalTo: Date(), toGranularity: .month)
    }

    private func shift(_ delta: Int) {
        month = Calendar.current.date(byAdding: .month, value: delta, to: month) ?? month
    }

    private var groups: [(Date, [LookSession])] {
        let cal = Calendar.current
        let dict = Dictionary(grouping: sessions) { cal.startOfDay(for: $0.openedAt) }
        return dict.keys.sorted(by: >).map { ($0, dict[$0] ?? []) }
    }

    var body: some View {
        ScreenScroll {
            PageHeader(
                title: "المبيعات",
                subtitle: "جلسات نقطة البيع",
                subtitleAbove: true,
                trailing: AnyView(monthSwitcher)
            )
            if let summary {
                summaryCard(summary).padding(.top, 18)
                if sessions.isEmpty {
                    EmptyCard(text: "لا توجد جلسات في هذا الشهر").padding(.top, 18)
                } else {
                    ForEach(groups.indices, id: \.self) { i in
                        let day = groups[i].0
                        let list = groups[i].1
                        SectionHeader(title: "\(weekday(day))، \(dayMonth(day))").padding(.top, 18)
                        GroupedList(list) { s in
                            ListRow(
                                title: s.staffLabel,
                                subtitle: "\(time12(s.openedAt)) · \(s.invoiceCount) فاتورة",
                                trailing: AnyView(HStack(spacing: 6) {
                                    MoneyText(value: s.total)
                                    Image(systemName: "chevron.forward").font(.system(size: 12, weight: .semibold)).foregroundStyle(MF.goldText)
                                }),
                                action: { router.push(.session(s)) }
                            )
                        }
                    }
                }
            } else {
                LoadingView()
            }
        }
        .task(id: month) {
            summary = nil
            let c = Calendar.current.dateComponents([.year, .month], from: month)
            async let a = store.repo.monthSummary(year: c.year ?? 2026, month: c.month ?? 1)
            async let b = store.repo.sessions(year: c.year ?? 2026, month: c.month ?? 1)
            let (s, list) = await (a, b)
            summary = s
            sessions = list
        }
    }

    private var monthSwitcher: some View {
        HStack(spacing: 0) {
            Button { shift(-1) } label: {
                Image(systemName: "chevron.backward").frame(width: 36, height: 36)
            }
            .accessibilityLabel("الشهر السابق")
            Text(arMonths[Calendar.current.component(.month, from: month) - 1]).font(MFFont.body(13, .semibold))
            Button { shift(1) } label: {
                Image(systemName: "chevron.forward").frame(width: 36, height: 36)
            }
            .disabled(isCurrentMonth)
            .accessibilityLabel("الشهر التالي")
        }
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(MF.ink)
        .padding(.horizontal, 4)
        .frame(height: 44)
        .background(Color.white, in: Capsule())
        .softShadow(8)
    }

    private func summaryCard(_ s: MonthSummary) -> some View {
        MfCard(radius: 26, padding: EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)) {
            Text("المجموع الكلي").font(MFFont.body(12.5)).foregroundStyle(MF.ink2)
            MoneyText(value: s.total, size: 34, weight: .light, currency: true).padding(.top, 2)
            SplitBar(fraction: s.posShare, first: MF.pine, second: MF.gold, height: 8).padding(.top, 16)
            HStack(alignment: .top) {
                stat("POS", money(s.posAmount), MF.pine)
                stat("خارج", money(s.outsideAmount), MF.gold)
                stat("جلسات · فواتير", "\(s.sessions) · \(s.invoices)", nil)
            }
            .padding(.top, 14)
        }
    }

    private func stat(_ label: String, _ value: String, _ dot: Color?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            if let dot {
                LegendDot(color: dot, label: label)
            } else {
                Text(label).font(MFFont.body(11.5)).foregroundStyle(MF.ink2)
            }
            Text(value).font(MFFont.display(14, .medium)).foregroundStyle(MF.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct LiveSessionDetailView: View {
    let sessionId: String
    @Environment(AppStore.self) private var store
    @Environment(Router.self) private var router
    @State private var session: LookSession?

    var body: some View {
        Group {
            if let session {
                SessionDetailView(session: session)
            } else {
                ScreenScroll {
                    PageHeader(title: "تفاصيل الجلسة", onBack: { router.pop() })
                    LoadingView()
                }
                .task { session = await store.repo.session(id: sessionId) }
            }
        }
    }
}

struct SessionDetailView: View {
    let session: LookSession
    @Environment(Router.self) private var router

    var body: some View {
        let s = session
        ScreenScroll(bottom: 32) {
            PageHeader(
                title: "جلسة \(weekday(s.openedAt))",
                subtitle: (s.closedBy == nil || s.closedBy == s.openedBy)
                    ? "فتحها وأغلقها \(s.openedBy)"
                    : "فتحها \(s.openedBy) · أغلقتها \(s.closedBy ?? "")",
                onBack: { router.pop() },
                trailing: AnyView(StatusPill(label: s.isClosed ? "جلسة مغلقة" : "جلسة مفتوحة"))
            )
            PineCard(padding: 20, ringsCenter: UnitPoint(x: -0.08, y: 1.3), ringsRadius: 120) {
                Text("مجموع الجلسة").font(MFFont.body(12.5)).foregroundStyle(MF.onPineMuted)
                MoneyText(value: s.total, size: 36, weight: .light, color: .white, currency: true, currencyColor: MF.gold)
                    .padding(.top, 4)
                Rectangle().fill(MF.gold.opacity(0.25)).frame(height: 1).padding(.vertical, 14)
                HStack {
                    pineStat("فواتير", "\(s.invoiceCount)")
                    pineStat("POS", moneyOrDash(s.posAmount))
                    pineStat("خارج", moneyOrDash(s.outsideAmount))
                }
            }
            .padding(.top, 18)
            HStack(spacing: 10) {
                timeChip(MF.success, "الفتح", "\(dayMonth(s.openedAt)) · \(time12(s.openedAt))")
                timeChip(MF.goldText, "الغلق", s.closedAt.map { "\(dayMonth($0)) · \(time12($0))" } ?? "—")
            }
            .padding(.top, 14)
            SectionHeader(title: "الفواتير").padding(.top, 22)
            if s.orders.isEmpty {
                EmptyCard(text: "تفاصيل الفواتير غير متوفرة")
            } else {
                GroupedList(s.orders) { o in orderTile(o) }
            }
        }
    }

    private func pineStat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label).font(MFFont.body(11.5)).foregroundStyle(MF.onPineMuted)
            Text(value).font(MFFont.display(16, .medium)).foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func timeChip(_ dot: Color, _ label: String, _ value: String) -> some View {
        MfCard(radius: 18, padding: EdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14)) {
            LegendDot(color: dot, label: label)
            Text(value).font(MFFont.body(13.5, .semibold)).foregroundStyle(MF.ink).padding(.top, 2)
        }
    }

    private func orderTile(_ o: LookOrder) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 8) {
                Text(o.ref).font(MFFont.display(14)).foregroundStyle(MF.ink)
                Text("\(o.customer) · \(time12(o.time))").font(MFFont.body(12)).foregroundStyle(MF.ink2)
                Spacer()
                MoneyText(value: o.total)
            }
            .padding(.bottom, 3)
            ForEach(o.lines, id: \.self) { l in
                HStack {
                    Text(l.name).font(MFFont.body(12.5)).foregroundStyle(Color(hex: 0x3F4B47)).lineLimit(1)
                    Spacer(minLength: 10)
                    Text("\(qtyText(l.qty)) × \(money(l.unitPrice))").font(MFFont.body(12.5)).foregroundStyle(MF.ink2)
                }
            }
        }
        .padding(.vertical, 12)
    }
}
