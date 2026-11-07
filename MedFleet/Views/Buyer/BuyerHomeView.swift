import SwiftUI

enum BuyerRoute: Hashable {
    case scan
    case inventory
    case inventoryAudit
    case purchaseReturns
    case posSessions
    case settings
}

struct BuyerHomeView: View {
    @EnvironmentObject var tokenStore: TokenStore
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var connectivity: Connectivity

    @State private var path = NavigationPath()
    @State private var tab = 0

    private var isAdmin: Bool { tokenStore.user?.canSeePos == true }
    private var displayName: String {
        let n = tokenStore.user?.name ?? ""
        return n.isEmpty ? "المشتري" : n
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .bottom) {
                MFColors.porcelain.ignoresSafeArea()
                Group {
                    switch tab {
                    case 0: homeTab
                    case 1: BuyerInventoryView()
                    case 2:
                        if isAdmin { BuyerPosSessionsView() } else { BuyerSettingsView() }
                    default:
                        BuyerSettingsView()
                    }
                }
                .padding(.bottom, 92)

                tabBar
            }
            .navigationDestination(for: BuyerRoute.self) { route in
                Group {
                    switch route {
                    case .scan: BuyerScanView()
                    case .inventory: BuyerInventoryView()
                    case .inventoryAudit: BuyerInventoryAuditView()
                    case .purchaseReturns: BuyerPurchaseReturnsView()
                    case .posSessions: BuyerPosSessionsView()
                    case .settings: BuyerSettingsView()
                    }
                }
                .toolbar(.hidden, for: .navigationBar)
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .preferredColorScheme(.light)
    }

    private var homeTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if !connectivity.isOnline { OfflineBanner() }
                HStack {
                    Circle()
                        .fill(MFColors.pine)
                        .frame(width: 48, height: 48)
                        .overlay(
                            Text(String(displayName.prefix(1)))
                                .font(.system(size: 18, weight: .semibold, design: .serif))
                                .foregroundStyle(MFColors.gold)
                        )
                        .overlay(Circle().stroke(MFColors.gold.opacity(0.6), lineWidth: 1))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(isAdmin ? "لوحة المدير" : "لوحة الموظف")
                            .font(.system(size: 12))
                            .foregroundStyle(MFColors.muted)
                        Text(displayName)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(MFColors.ink)
                    }
                    Spacer()
                }
                .padding(.top, 8)

                HStack(spacing: 10) {
                    quick("مسح فاتورة", "doc.text.viewfinder") { path.append(BuyerRoute.scan) }
                    quick("الجرد", "checkmark.square") { path.append(BuyerRoute.inventoryAudit) }
                    quick("المردود", "arrow.uturn.left") { path.append(BuyerRoute.purchaseReturns) }
                    if isAdmin {
                        quick("المبيعات", "chart.line.uptrend.xyaxis") { tab = 2 }
                    } else {
                        quick("المخزن", "shippingbox") { tab = 1 }
                    }
                }

                Text("الأقسام")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(MFColors.muted)
                VStack(spacing: 0) {
                    row("ماسحة الفاتورة", "doc.text") { path.append(BuyerRoute.scan) }
                    Divider()
                    row("المخزن", "shippingbox") { tab = 1 }
                    Divider()
                    row("الجرد المخزني", "square.grid.2x2") { path.append(BuyerRoute.inventoryAudit) }
                    Divider()
                    row("مردود الشراء", "arrow.uturn.left") { path.append(BuyerRoute.purchaseReturns) }
                    if isAdmin {
                        Divider()
                        row("جلسات نقطة البيع", "rectangle.split.3x1") { tab = 2 }
                    }
                    Divider()
                    row("الإعدادات", "gearshape") { tab = 3 }
                }
                .background(Color.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: MFColors.ink.opacity(0.07), radius: 14, y: 8)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }

    private func quick(_ title: String, _ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.white)
                    .frame(width: 62, height: 62)
                    .shadow(color: MFColors.ink.opacity(0.07), radius: 10, y: 6)
                    .overlay(Image(systemName: icon).font(.system(size: 20, weight: .medium)).foregroundStyle(MFColors.pine))
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(MFColors.ink)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private func row(_ title: String, _ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(MFColors.pine)
                    .frame(width: 36, height: 36)
                    .background(MFColors.accentSoft, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MFColors.ink)
                Spacer()
                Image(systemName: "chevron.left")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MFColors.goldDark)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    private var tabBar: some View {
        HStack {
            tabItem(0, "house", "الرئيسية")
            tabItem(1, "shippingbox", "المخزن")
            Spacer().frame(width: 58)
            if isAdmin {
                tabItem(2, "chart.line.uptrend.xyaxis", "المبيعات")
                tabItem(3, "gearshape", "الإعدادات")
            } else {
                tabItem(2, "gearshape", "الإعدادات")
            }
        }
        .padding(.horizontal, 8)
        .frame(height: 68)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: MFColors.ink.opacity(0.1), radius: 16, y: 6)
        .overlay(alignment: .top) {
            Button { path.append(BuyerRoute.scan) } label: {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(MFColors.pine)
                    .frame(width: 58, height: 58)
                    .overlay(Image(systemName: "doc.viewfinder").font(.system(size: 22, weight: .medium)).foregroundStyle(MFColors.gold))
                    .shadow(color: MFColors.pine.opacity(0.35), radius: 12, y: 6)
            }
            .offset(y: -18)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    private func tabItem(_ index: Int, _ icon: String, _ label: String) -> some View {
        Button {
            tab = index
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: tab == index ? .bold : .medium))
                Text(label)
                    .font(.system(size: 11, weight: tab == index ? .bold : .medium))
            }
            .foregroundStyle(tab == index ? MFColors.pine : MFColors.muted)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
