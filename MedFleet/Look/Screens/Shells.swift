import SwiftUI

/// واجهة المدير: الرئيسية، المخزن، المبيعات، الإعدادات — بدون بصمة.
struct AdminShell: View {
    let user: AppUser
    @Environment(Router.self) private var router
    @State private var tab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch tab {
                case 0: AdminHomeView(user: user, openSales: { tab = 2 }, openSettings: { tab = 3 })
                case 1: InventoryView(showCost: true)
                case 2: SessionsView()
                default: SettingsView(user: user)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            MfTabBar(
                items: [
                    TabItem(icon: "house", activeIcon: "house.fill", label: "الرئيسية"),
                    TabItem(icon: "shippingbox", activeIcon: "shippingbox.fill", label: "المخزن"),
                    TabItem(icon: "chart.line.uptrend.xyaxis", activeIcon: "chart.line.uptrend.xyaxis", label: "المبيعات"),
                    TabItem(icon: "gearshape", activeIcon: "gearshape.fill", label: "الإعدادات"),
                ],
                current: $tab,
                onCenter: { router.push(.scanner(.invoice)) }
            )
        }
        .background(MF.porcelain.ignoresSafeArea())
        .ignoresSafeArea(.keyboard)
    }
}

/// واجهة الموظف: الرئيسية، المخزن، الحضور (البصمة)، الإعدادات — بدون المبيعات والجلسات.
struct EmployeeShell: View {
    let user: AppUser
    @Environment(Router.self) private var router
    @State private var tab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch tab {
                case 0: EmployeeHomeView(user: user, openAttendance: { tab = 2 }, openInventory: { tab = 1 }, openSettings: { tab = 3 })
                case 1: InventoryView(showCost: false)
                case 2: AttendanceView(user: user)
                default: SettingsView(user: user)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            MfTabBar(
                items: [
                    TabItem(icon: "house", activeIcon: "house.fill", label: "الرئيسية"),
                    TabItem(icon: "shippingbox", activeIcon: "shippingbox.fill", label: "المخزن"),
                    TabItem(icon: "touchid", activeIcon: "touchid", label: "الحضور"),
                    TabItem(icon: "gearshape", activeIcon: "gearshape.fill", label: "الإعدادات"),
                ],
                current: $tab,
                onCenter: { router.push(.scanner(.invoice)) }
            )
        }
        .background(MF.porcelain.ignoresSafeArea())
        .ignoresSafeArea(.keyboard)
    }
}
