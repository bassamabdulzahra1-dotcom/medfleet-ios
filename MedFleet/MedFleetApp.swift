import SwiftUI
import FirebaseMessaging

@main
struct MedFleetApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var tokenStore = TokenStore()
    @StateObject private var appState = AppState()
    @StateObject private var connectivity = Connectivity()
    @StateObject private var posMonitor = PosSessionMonitor()

    var body: some Scene {
        WindowGroup {
            UpdateGate { RootView() }
                .environmentObject(tokenStore)
                .environmentObject(appState)
                .environmentObject(connectivity)
                .environmentObject(posMonitor)
                .environment(\.layoutDirection, .rightToLeft)
                .tint(MFColors.pine)
                .preferredColorScheme(.light)
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
    @State private var router = Router()
    @State private var store: AppStore?

    var body: some View {
        Group {
            if showSplash {
                SplashView {
                    withAnimation(.easeOut(duration: 0.45)) { showSplash = false }
                }
            } else if tokenStore.isLoggedIn, tokenStore.user?.role == "buyer", let store {
                loggedIn(store: store)
            } else {
                LoginView()
                    .onAppear {
                        if tokenStore.isLoggedIn, tokenStore.user?.role != "buyer" {
                            tokenStore.clear()
                        }
                    }
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .tint(MF.pine)
        .preferredColorScheme(.light)
        .onAppear {
            appState.setup(tokenStore: tokenStore)
            if store == nil {
                store = AppStore(repo: LiveLookRepository(appState: appState))
            }
        }
    }

    @ViewBuilder
    private func loggedIn(store: AppStore) -> some View {
        let user = tokenStore.user?.toAppUser() ?? AppUser(id: "", name: "المشتري", email: "", role: .employee, jobTitle: "صيدلي")
        NavigationStack(path: Binding(get: { router.path }, set: { router.path = $0 })) {
            Group {
                if user.isAdmin {
                    AdminShell(user: user)
                } else {
                    EmployeeShell(user: user)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Route.self) { route in
                destination(route)
                    .toolbar(.hidden, for: .navigationBar)
            }
        }
        .id(user.id)
        .environment(store)
        .environment(router)
        .onAppear {
            PushRegistrar.sync(api: appState.api, tokenStore: tokenStore)
            if tokenStore.user?.canSeePos == true {
                posMonitor.start(appState: appState)
            } else {
                posMonitor.stop()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .mfFcmToken)) { _ in
            PushRegistrar.sync(api: appState.api, tokenStore: tokenStore)
        }
    }

    @ViewBuilder
    private func destination(_ route: Route) -> some View {
        switch route {
        case .scanner(.invoice):
            BuyerScanView()
        case .scanner(.barcode):
            ScannerView(mode: .barcode)
        case .stocktake:
            BuyerInventoryAuditView()
        case .returns:
            ReturnsView()
        case .returnNew:
            BuyerPurchaseReturnEditorView(onSaved: { router.pop() })
        case .session(let s):
            if s.orders.isEmpty {
                LiveSessionDetailView(sessionId: s.id)
            } else {
                SessionDetailView(session: s)
            }
        case .team:
            TeamAttendanceView()
        }
    }
}
