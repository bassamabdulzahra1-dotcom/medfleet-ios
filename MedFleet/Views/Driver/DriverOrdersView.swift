import SwiftUI

struct DriverOrdersView: View {
    @EnvironmentObject var tokenStore: TokenStore
    @EnvironmentObject var appState: AppState
    @State private var orders: [DeliveryOrder] = []
    @State private var loading = true

    var body: some View {
        NavigationStack {
            Group {
                if loading { ProgressView() }
                else if orders.isEmpty { Text("لا توجد طلبات اليوم").foregroundStyle(MFColors.muted) }
                else {
                    List(orders) { o in
                        VStack(alignment: .trailing) {
                            Text(o.pharmacyName ?? o.orderCode).font(.headline)
                            Text(MFFormat.statusAr(o.status)).font(.caption)
                        }
                    }
                }
            }
            .navigationTitle("طلبات التوصيل")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("خروج") { Task { await appState.api?.logout() } }
                }
            }
        }
        .task { await load() }
        .environment(\.layoutDirection, .rightToLeft)
    }

    private func load() async {
        guard let api = appState.api else { return }
        orders = (try? await api.listOrdersToday()) ?? []
        loading = false
    }
}
