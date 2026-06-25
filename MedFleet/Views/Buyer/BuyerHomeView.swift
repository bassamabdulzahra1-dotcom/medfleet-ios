import SwiftUI

enum BuyerRoute: Hashable {
    case scan
    case inventory
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
                VStack(alignment: .trailing, spacing: 12) {
                    if !connectivity.isOnline {
                        OfflineBanner()
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    VStack(spacing: 4) {
                        Text(displayName)
                            .font(.title3.bold())
                            .foregroundStyle(MFColors.navy)
                        Text("لوحة المشتري")
                            .font(.caption)
                            .foregroundStyle(MFColors.gold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

                    Text("الأقسام")
                        .font(.subheadline)
                        .foregroundStyle(MFColors.muted)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.horizontal, 4)

                    moduleCard(
                        title: "ماسحة الفاتورة",
                        subtitle: "صوّر فاتورة الشراء واستخرج الأصناف تلقائياً",
                        icon: "doc.text.viewfinder",
                        tint: Color(red: 0.94, green: 0.38, blue: 0.31),
                        bg: Color(red: 1, green: 0.92, blue: 0.91)
                    ) { path.append(BuyerRoute.scan) }

                    moduleCard(
                        title: "المخزن",
                        subtitle: "استعرض المنتجات والأرصدة والأسعار",
                        icon: "shippingbox.fill",
                        tint: Color(red: 0.18, green: 0.49, blue: 0.20),
                        bg: Color(red: 0.91, green: 0.96, blue: 0.91)
                    ) { path.append(BuyerRoute.inventory) }

                    moduleCard(
                        title: "الإعدادات",
                        subtitle: "بيانات الحساب وسياسة الخصوصية وحذف الحساب",
                        icon: "gearshape.fill",
                        tint: Color(red: 0.36, green: 0.42, blue: 0.75),
                        bg: Color(red: 0.91, green: 0.92, blue: 0.96)
                    ) { path.append(BuyerRoute.settings) }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 24)
            }
            .background(LinearGradient(colors: [MFColors.bgTop, MFColors.bgBottom], startPoint: .top, endPoint: .bottom).ignoresSafeArea())
            .safeAreaInset(edge: .top) {
                HStack {
                    Button {
                        Task { await logout() }
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundStyle(MFColors.gold)
                            .padding(10)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.06), radius: 3, y: 1)
                    }
                    Spacer()
                }
                .padding(.horizontal, 18)
                .padding(.top, 4)
            }
            .navigationDestination(for: BuyerRoute.self) { route in
                Group {
                    switch route {
                    case .scan: BuyerScanView()
                    case .inventory: BuyerInventoryView()
                    case .settings: BuyerSettingsView()
                    }
                }
                .toolbar(.hidden, for: .navigationBar)
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }

    private func logout() async {
        await appState.api?.logout()
        tokenStore.clear()
    }

    @ViewBuilder
    private func moduleCard(title: String, subtitle: String, icon: String, tint: Color, bg: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(bg)
                    .frame(width: 56, height: 56)
                    .overlay(Image(systemName: icon).font(.title2).foregroundStyle(tint))
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(title).font(.body.weight(.semibold)).foregroundStyle(MFColors.navy)
                    Text(subtitle).font(.caption).foregroundStyle(MFColors.muted)
                        .multilineTextAlignment(.trailing)
                }
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }
}
