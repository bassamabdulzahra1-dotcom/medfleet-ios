import SwiftUI

struct GreetingHeader: View {
    let user: AppUser
    let onAvatar: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onAvatar) {
                Text(user.initial)
                    .font(MFFont.logo(19))
                    .foregroundStyle(MF.gold)
                    .frame(width: 42, height: 42)
                    .background(MF.pine, in: Circle())
                    .padding(3)
                    .overlay(Circle().stroke(MF.gold.opacity(0.6), lineWidth: 1))
            }
            .buttonStyle(PressStyle())
            .accessibilityLabel("الحساب")

            VStack(alignment: .leading, spacing: 0) {
                Text(greeting(Date())).font(MFFont.body(12.5)).foregroundStyle(MF.ink2)
                Text(user.name).font(MFFont.display(18)).foregroundStyle(MF.ink)
            }
            Spacer()
            CircleIconButton(systemName: "bell", label: "الإشعارات") {}
        }
    }
}

// MARK: - رئيسية المدير

struct AdminHomeView: View {
    let user: AppUser
    let openSales: () -> Void
    let openSettings: () -> Void

    @Environment(AppStore.self) private var store
    @Environment(Router.self) private var router
    @State private var summary: MonthSummary?
    @State private var sessions: [LookSession] = []

    private let now = Date()

    var body: some View {
        ScreenScroll {
            GreetingHeader(user: user, onAvatar: openSettings)
            if let summary {
                Button(action: openSales) { monthCard(summary) }
                    .buttonStyle(PressStyle())
                    .padding(.top, 20)

                HStack {
                    QuickAction(systemImage: "doc.text", label: "مسح فاتورة") { router.push(.scanner(.invoice)) }
                    Spacer()
                    QuickAction(systemImage: "checklist", label: "الجرد") { router.push(.stocktake) }
                    Spacer()
                    QuickAction(systemImage: "arrow.uturn.backward", label: "المردود") { router.push(.returns) }
                    Spacer()
                    QuickAction(systemImage: "person.3", label: "حضور الفريق") { router.push(.team) }
                }
                .padding(.top, 24)

                SectionHeader(title: "آخر الجلسات", action: "عرض الكل", onAction: openSales)
                    .padding(.top, 26)
                if sessions.isEmpty {
                    EmptyCard(text: "لا توجد جلسات هذا الشهر")
                } else {
                    GroupedList(Array(sessions.prefix(3))) { s in
                        ListRow(
                            title: s.staffLabel,
                            subtitle: "\(weekday(s.openedAt)) · \(time12(s.openedAt)) · \(s.invoiceCount) فاتورة",
                            leading: AnyView(IconTile(text: "\(Calendar.current.component(.day, from: s.openedAt))", size: 42, radius: 13)),
                            trailing: AnyView(MoneyText(value: s.total)),
                            action: { router.push(.session(s)) }
                        )
                    }
                }
            } else {
                LoadingView()
            }
        }
        .task {
            let c = Calendar.current.dateComponents([.year, .month], from: now)
            async let a = store.repo.monthSummary(year: c.year ?? 2026, month: c.month ?? 1)
            async let b = store.repo.sessions(year: c.year ?? 2026, month: c.month ?? 1)
            let (s, list) = await (a, b)
            summary = s
            sessions = list
        }
    }

    private func monthCard(_ s: MonthSummary) -> some View {
        PineCard {
            HStack {
                Text("مبيعات \(arMonths[Calendar.current.component(.month, from: now) - 1])")
                    .font(MFFont.body(13)).foregroundStyle(MF.onPineMuted)
                Spacer()
                Text("MEDFLEET").font(MFFont.logo(12)).tracking(4).foregroundStyle(MF.gold)
            }
            MoneyText(value: s.total, size: 40, weight: .light, color: .white, currency: true, currencyColor: MF.gold)
                .padding(.top, 14)
            SplitBar(fraction: s.posShare, first: MF.gold, second: MF.mint)
                .padding(.top, 34)
            HStack {
                LegendDot(color: MF.gold, label: "POS \(money(s.posAmount))", textColor: MF.onPineMuted)
                Spacer()
                LegendDot(color: MF.mint, label: "خارج \(money(s.outsideAmount))", textColor: MF.onPineMuted)
                Spacer()
                Text("\(s.invoices) فاتورة").font(MFFont.body(12)).foregroundStyle(MF.onPineMuted)
            }
            .padding(.top, 10)
        }
    }
}

// MARK: - رئيسية الموظف

struct EmployeeHomeView: View {
    let user: AppUser
    let openAttendance: () -> Void
    let openInventory: () -> Void
    let openSettings: () -> Void

    @Environment(AppStore.self) private var store
    @Environment(Router.self) private var router
    @State private var products: [LookProduct]?
    @State private var record: AttendanceRecord?

    var body: some View {
        ScreenScroll {
            GreetingHeader(user: user, onAvatar: openSettings)
            Button(action: openAttendance) { attendanceCard }
                .buttonStyle(PressStyle())
                .padding(.top, 20)

            HStack {
                QuickAction(systemImage: "doc.text", label: "مسح فاتورة") { router.push(.scanner(.invoice)) }
                Spacer()
                QuickAction(systemImage: "checklist", label: "الجرد") { router.push(.stocktake) }
                Spacer()
                QuickAction(systemImage: "arrow.uturn.backward", label: "المردود") { router.push(.returns) }
                Spacer()
                QuickAction(systemImage: "shippingbox", label: "المخزن", action: openInventory)
            }
            .padding(.top, 24)

            SectionHeader(title: "أصناف رصيدها منخفض", action: "المخزن", onAction: openInventory)
                .padding(.top, 26)
            if let products {
                let low = products.filter(\.isLowStock)
                if low.isEmpty {
                    EmptyCard(text: "كل الأصناف رصيدها جيد")
                } else {
                    GroupedList(low) { p in
                        ListRow(
                            title: p.name,
                            subtitle: p.generic,
                            leading: AnyView(IconTile(text: String(p.name.prefix(1)), bg: MF.warnTint, fg: MF.warnText)),
                            trailing: AnyView(StatusPill(label: "الرصيد \(p.stock ?? 0)", bg: MF.warnTint, fg: MF.warnText))
                        )
                    }
                }
            } else {
                LoadingView()
            }
        }
        .task { products = await store.repo.products() }
        .task(id: store.attendanceVersion) { record = await store.repo.myAttendanceToday(user) }
    }

    private var attendanceCard: some View {
        let status: String
        let cta: String
        if let r = record {
            if let inAt = r.checkIn {
                if let outAt = r.checkOut {
                    status = "انصرفت الساعة \(time12(outAt))"; cta = "عرض اليوم"
                } else {
                    status = "حضرت الساعة \(time12(inAt))"; cta = "سجّل انصرافك"
                }
            } else {
                status = "لم تسجّل حضورك اليوم بعد"; cta = "سجّل حضورك"
            }
        } else {
            status = "…"; cta = "الحضور"
        }

        return PineCard {
            HStack {
                Text("بصمة الحضور").font(MFFont.body(13)).foregroundStyle(MF.onPineMuted)
                Spacer()
                Image(systemName: "touchid").foregroundStyle(MF.gold)
            }
            LiveClock { now in
                (Text(hm(now)).font(MFFont.display(44, .ultraLight)).foregroundColor(.white)
                    + Text("  \(amPm(now))").font(MFFont.body(16)).foregroundColor(MF.gold))
                    .environment(\.layoutDirection, .leftToRight)
            }
            .padding(.top, 12)
            Text(status).font(MFFont.body(13)).foregroundStyle(MF.onPineMuted).padding(.top, 6)
            HStack(spacing: 8) {
                Text(cta).font(MFFont.body(14, .bold))
                Image(systemName: "arrow.forward").font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(MF.pine)
            .padding(.horizontal, 18)
            .frame(height: 46)
            .background(MF.gold, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
            .padding(.top, 18)
        }
    }
}
