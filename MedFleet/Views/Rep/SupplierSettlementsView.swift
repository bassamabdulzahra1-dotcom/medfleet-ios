import SwiftUI

struct SupplierSettlementsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var connectivity: Connectivity

    @State private var plans: [PaymentPlan] = []
    @State private var loading = true
    @State private var deleteTarget: PaymentPlan?
    @State private var snack: String?

    var body: some View {
        OpenModuleLayout(onBack: { dismiss() }) {
            VStack(spacing: 0) {
                if !connectivity.isOnline { OfflineBanner() }
                Group {
                    if loading && plans.isEmpty {
                        ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if plans.isEmpty {
                        Text("لا توجد تسديدات فعلية بعد").foregroundStyle(MFColors.muted).frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List(plans) { p in
                            NavigationLink(value: AppRoute.paymentPlan(p.id)) {
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text(p.supplierName ?? "مورد").font(.headline)
                                    Text("مدفوع: \(MFFormat.money(p.paidTotal ?? 0)) د.ع")
                                    Text(MFFormat.dueDate(p.createdAt)).font(.caption).foregroundStyle(MFColors.muted)
                                }
                            }
                            .swipeActions {
                                if (p.paidTotal ?? 0) <= 0.01 {
                                    Button(role: .destructive) { deleteTarget = p } label: { Label("حذف", systemImage: "trash") }
                                }
                            }
                        }
                    }
                }
            }
        }
        .task(id: appState.settlementsRefresh) { await load() }
        .overlay(alignment: .bottom) {
            if let snack { Text(snack).padding().background(.ultraThinMaterial).clipShape(Capsule()).padding() }
        }
        .alert("حذف التسديد؟", isPresented: Binding(get: { deleteTarget != nil }, set: { if !$0 { deleteTarget = nil } })) {
            Button("حذف", role: .destructive) {
                if let p = deleteTarget { Task { await deletePlan(p) } }
            }
            Button("إلغاء", role: .cancel) {}
        }
    }

    private func load() async {
        guard let api = appState.api else { return }
        if let c = appState.cache.getSettlements() { plans = c; loading = false }
        if let list = try? await api.listPaymentPlans(paidOnly: true) {
            plans = list
            appState.cache.putSettlements(list)
            appState.offline.save(list, key: OfflineKey.settlements)
        } else if plans.isEmpty, let cached = appState.offline.load([PaymentPlan].self, key: OfflineKey.settlements) {
            plans = cached
        }
        loading = false
    }

    private func deletePlan(_ plan: PaymentPlan) async {
        guard let api = appState.api else { return }
        deleteTarget = nil
        guard connectivity.isOnline else { snack = "لا يمكن حذف التسديد بدون إنترنت"; return }
        plans.removeAll { $0.id == plan.id }
        try? await api.deletePaymentPlan(id: plan.id)
        appState.invalidateSettlementsRefresh()
    }
}

private extension AppState {
    func invalidateSettlementsRefresh() {
        cache.invalidateSettlements()
        settlementsRefresh += 1
    }
}
