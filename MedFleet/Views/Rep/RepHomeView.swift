import SwiftUI

struct RepHomeView: View {
    @EnvironmentObject var tokenStore: TokenStore
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var connectivity: Connectivity

    @State private var appointmentCount = 0
    @State private var appointmentsTotal = 0.0
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .trailing, spacing: 10) {
                    if !connectivity.isOnline {
                        OfflineBanner()
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    VStack(spacing: 4) {
                        Text("MedFleet").font(.title2.bold()).foregroundStyle(MFColors.navy)
                        if let name = tokenStore.user?.name {
                            Text(name).font(.caption).foregroundStyle(MFColors.muted)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

                    Text("الأقسام")
                        .font(.subheadline)
                        .foregroundStyle(MFColors.muted)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.horizontal, 4)

                    moduleCard(title: "الموردين", icon: "building.columns.fill", tint: MFColors.accentDark, bg: MFColors.accentSoft) {
                        path.append(AppRoute.suppliers)
                    }
                    moduleCard(title: "تسديدات الموردين", icon: "banknote.fill", tint: MFColors.accent, bg: MFColors.surfaceSoft) {
                        path.append(AppRoute.settlements)
                    }
                    moduleCard(title: "المواعيد", icon: "calendar", tint: MFColors.navy2, bg: MFColors.accentSoft, badge: appointmentCount, subtitle: appointmentsTotal > 0 ? "\(MFFormat.money(appointmentsTotal)) د.ع" : nil) {
                        path.append(AppRoute.appointments)
                    }
                    moduleCard(title: "حسابي", icon: "person.fill", tint: MFColors.ok, bg: MFColors.surfaceSoft) {
                        path.append(AppRoute.account)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 24)
            }
            .background(LinearGradient(colors: [MFColors.bgTop, MFColors.bgBottom], startPoint: .top, endPoint: .bottom).ignoresSafeArea())
            .navigationDestination(for: AppRoute.self) { route in
                Group {
                    switch route {
                    case .suppliers: SupplierPaymentsView()
                    case .settlements: SupplierSettlementsView()
                    case .appointments: AppointmentsView()
                    case .account: AccountView()
                    case .paymentPlan(let id): PaymentPlanDetailView(planId: id)
                    }
                }
                .toolbar(.hidden, for: .navigationBar)
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .task(id: appState.appointmentsRefresh) { await loadReminders() }
    }

    private func loadReminders() async {
        guard let api = appState.api else { return }
        if let r = try? await api.getReminders() {
            appointmentCount = r.count ?? r.data.count
            appointmentsTotal = r.totalAmount ?? r.data.reduce(0) { $0 + $1.amount }
            appState.offline.save(r.data, key: OfflineKey.reminders)
        } else if let cached = appState.offline.load([Reminder].self, key: OfflineKey.reminders) {
            appointmentCount = cached.count
            appointmentsTotal = cached.reduce(0) { $0 + $1.amount }
        }
    }

    @ViewBuilder
    private func moduleCard(title: String, icon: String, tint: Color, bg: Color, badge: Int = 0, subtitle: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(bg)
                    .frame(width: 52, height: 52)
                    .overlay(Image(systemName: icon).font(.title2).foregroundStyle(tint))
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 8) {
                        if badge > 0 {
                            Text(badge > 99 ? "99+" : "\(badge)")
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(MFColors.accentDark)
                                .clipShape(Capsule())
                        }
                        Text(title).font(.body.weight(.medium)).foregroundStyle(MFColors.navy)
                    }
                    if let subtitle {
                        Text(subtitle).font(.subheadline.weight(.semibold)).foregroundStyle(MFColors.accentDark)
                    }
                }
            }
            .padding(14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }
}
