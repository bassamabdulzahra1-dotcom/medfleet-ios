import SwiftUI

@main
struct MedFleetApp: App {
    @StateObject private var tokenStore = TokenStore()
    @StateObject private var appState = AppState()
    @StateObject private var connectivity = Connectivity()
    @StateObject private var posMonitor = PosSessionMonitor()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(tokenStore)
                .environmentObject(appState)
                .environmentObject(connectivity)
                .environmentObject(posMonitor)
                .environment(\.layoutDirection, .rightToLeft)
                .tint(MFColors.gold)
        }
    }
}

@MainActor
final class AppState: ObservableObject {
    @Published var path = NavigationPath()
    @Published var appointmentsRefresh = 0
    @Published var settlementsRefresh = 0

    var api: APIClient?
    var cache = RepDataCache()
    let offline = OfflineStore()

    func setup(tokenStore: TokenStore) {
        if api == nil { api = APIClient(tokenStore: tokenStore) }
    }
}

final class RepDataCache {
    private var suppliers: [Supplier]?
    private var suppliersAt: Date?
    private var settlements: [PaymentPlan]?
    private var settlementsAt: Date?
    private let ttl: TimeInterval = 180

    func getSuppliers() -> [Supplier]? {
        guard let s = suppliers, let t = suppliersAt, Date().timeIntervalSince(t) < ttl else { return nil }
        return s
    }
    func putSuppliers(_ list: [Supplier]) { suppliers = list; suppliersAt = Date() }
    func invalidateSuppliers() { suppliers = nil }

    func getSettlements() -> [PaymentPlan]? {
        guard let s = settlements, let t = settlementsAt, Date().timeIntervalSince(t) < ttl else { return nil }
        return s
    }
    func putSettlements(_ list: [PaymentPlan]) { settlements = list; settlementsAt = Date() }
    func invalidateSettlements() { settlements = nil }
}

enum AppRoute: Hashable {
    case suppliers
    case settlements
    case appointments
    case account
    case paymentPlan(String)
}

struct RootView: View {
    @EnvironmentObject var tokenStore: TokenStore
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var posMonitor: PosSessionMonitor
    @State private var showSplash = true

    var body: some View {
        Group {
            if showSplash {
                SplashView {
                    withAnimation {
                        showSplash = false
                    }
                }
            } else if tokenStore.isLoggedIn, tokenStore.user?.role == "buyer" {
                BuyerHomeView()
                    .onAppear {
                        appState.setup(tokenStore: tokenStore)
                        if tokenStore.user?.canSeePos == true {
                            posMonitor.start(appState: appState)
                        } else {
                            posMonitor.stop()
                        }
                    }
            } else {
                LoginView()
                    .onAppear {
                        // أي جلسة قديمة بدور غير الصيدلية غير مدعومة — امسحها
                        if tokenStore.isLoggedIn, tokenStore.user?.role != "buyer" {
                            tokenStore.clear()
                        }
                    }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            appState.setup(tokenStore: tokenStore)
        }
    }
}
