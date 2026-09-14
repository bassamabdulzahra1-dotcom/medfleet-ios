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

    private var displayName: String {
        let n = tokenStore.user?.name ?? ""
        return n.isEmpty ? "المشتري" : n
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 12) {
                    if !connectivity.isOnline {
                        OfflineBanner()
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    VStack(spacing: 6) {
                        Text("MEDFLEET")
                            .font(.system(size: 32, weight: .bold))
                            .tracking(6)
                            .padding(.leading, 6)
                            .foregroundStyle(platinumTitle)
                            .environment(\.layoutDirection, .leftToRight)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.clear, Color(red: 203/255, green: 213/255, blue: 225/255), .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 60, height: 3)
                            .shadow(color: Color(red: 203/255, green: 213/255, blue: 225/255).opacity(0.4), radius: 8)
                            .padding(.bottom, 9)

                        Text(displayName)
                            .font(.system(size: 13))
                            .foregroundStyle(Color(red: 156/255, green: 163/255, blue: 175/255))
                        Text(tokenStore.user?.canSeePos == true ? "لوحة المدير" : "لوحة الموظف")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(red: 156/255, green: 163/255, blue: 175/255).opacity(0.85))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)
                    .padding(.bottom, 10)

                    moduleCard(title: "ماسحة الفاتورة", icon: "doc.text") {
                        path.append(BuyerRoute.scan)
                    }
                    moduleCard(title: "المخزن", icon: "shippingbox") {
                        path.append(BuyerRoute.inventory)
                    }
                    moduleCard(title: "الجرد المخزني", icon: "square.grid.2x2") {
                        path.append(BuyerRoute.inventoryAudit)
                    }
                    moduleCard(title: "مردود الشراء", icon: "arrow.uturn.left") {
                        path.append(BuyerRoute.purchaseReturns)
                    }
                    if tokenStore.user?.canSeePos == true {
                        moduleCard(title: "جلسات نقطة البيع", icon: "rectangle.split.3x1") {
                            path.append(BuyerRoute.posSessions)
                        }
                    }
                    moduleCard(title: "الإعدادات", icon: "gearshape") {
                        path.append(BuyerRoute.settings)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
                .frame(maxWidth: 420)
                .frame(maxWidth: .infinity)
            }
            .background(splashBackground.ignoresSafeArea())
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
        .preferredColorScheme(.dark)
    }

    private var splashBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 20/255, green: 22/255, blue: 24/255),
                Color(red: 34/255, green: 38/255, blue: 43/255),
                Color(red: 13/255, green: 15/255, blue: 17/255)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var platinumTitle: LinearGradient {
        LinearGradient(
            colors: [
                .white,
                Color(red: 203/255, green: 213/255, blue: 225/255),
                Color(red: 100/255, green: 116/255, blue: 139/255)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    @ViewBuilder
    private func moduleCard(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(red: 243/255, green: 244/255, blue: 246/255))
                Spacer()
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 17/255, green: 19/255, blue: 21/255).opacity(0.8))
                    .frame(width: 48, height: 48)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(red: 203/255, green: 213/255, blue: 225/255).opacity(0.1), lineWidth: 1)
                    )
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(Color(red: 203/255, green: 213/255, blue: 225/255))
                    )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(Color(red: 26/255, green: 28/255, blue: 32/255).opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(red: 203/255, green: 213/255, blue: 225/255).opacity(0.08), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 12, y: 4)
        }
        .buttonStyle(.plain)
    }
}
