import SwiftUI

@main
struct MedFleetApp: App {
    @StateObject private var tokenStore = TokenStore()
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(tokenStore)
                .environmentObject(appState)
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
    case pharmacies
    case addPharmacy
    case suppliers
    case settlements
    case appointments
    case account
    case paymentPlan(String)
    case driverOrders
}

struct RootView: View {
    @EnvironmentObject var tokenStore: TokenStore
    @EnvironmentObject var appState: AppState
    @State private var showSplash = true

    var body: some View {
        Group {
            if showSplash {
                SplashView()
            } else if tokenStore.isLoggedIn, let role = tokenStore.user?.role {
                if role == "driver" {
                    DriverOrdersView()
                } else {
                    RepHomeView()
                }
            } else {
                LoginView()
            }
        }
        .onAppear {
            appState.setup(tokenStore: tokenStore)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                withAnimation { showSplash = false }
            }
        }
    }
}
