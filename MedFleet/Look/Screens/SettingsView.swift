import SwiftUI
import UIKit

private struct SettingRow {
    let title: String
    var subtitle: String? = nil
    let icon: String
    var bg: Color = MF.mintTint
    var fg: Color = MF.pine
    var titleColor: Color = MF.ink
    var chevron = true
    let action: () -> Void
}

struct SettingsView: View {
    let user: AppUser
    @Environment(AppStore.self) private var store
    @Environment(Router.self) private var router
    @EnvironmentObject var tokenStore: TokenStore
    @EnvironmentObject var appState: AppState
    @State private var confirmDelete = false
    @State private var busy = false

    var body: some View {
        ScreenScroll {
            PageHeader(title: "الإعدادات")

            PineCard(padding: 20, ringsCenter: UnitPoint(x: -0.08, y: -0.5), ringsRadius: 110) {
                HStack(spacing: 16) {
                    Text(user.initial)
                        .font(MFFont.logo(28))
                        .foregroundStyle(MF.gold)
                        .frame(width: 64, height: 64)
                        .overlay(Circle().stroke(MF.gold, lineWidth: 1.5))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.name).font(MFFont.display(19, .medium)).foregroundStyle(.white)
                        Text(user.email).font(MFFont.body(13)).foregroundStyle(MF.onPineMuted)
                        StatusPill(label: user.isAdmin ? "مدير · صيدلية" : user.jobTitle, bg: MF.gold.opacity(0.18), fg: MF.goldSoft)
                            .padding(.top, 4)
                    }
                }
            }
            .padding(.top, 18)

            if user.isAdmin {
                SectionHeader(title: "الإدارة").padding(.top, 22)
                group([
                    SettingRow(title: "حضور الموظفين", icon: "person.3") { router.push(.team) },
                    SettingRow(title: "إدارة الموظفين والصلاحيات", icon: "person.text.rectangle") { /* TODO */ },
                ])
            }

            SectionHeader(title: "عام").padding(.top, 22)
            group([
                SettingRow(title: "سياسة الخصوصية", icon: "checkmark.shield", bg: MF.goldTint, fg: MF.goldText) {
                    if let url = URL(string: "https://medfleet.net/privacy") {
                        UIApplication.shared.open(url)
                    }
                },
            ])

            SectionHeader(title: "الحساب").padding(.top, 22)
            group([
                SettingRow(title: "تسجيل الخروج", icon: "rectangle.portrait.and.arrow.right", bg: Color(hex: 0xEEF0EF), fg: MF.ink, chevron: false) {
                    Task {
                        await appState.api?.logout()
                        tokenStore.clear()
                        store.user = nil
                        router.reset()
                    }
                },
                SettingRow(title: "حذف الحساب", subtitle: "إجراء نهائي لا يمكن التراجع عنه", icon: "trash",
                           bg: MF.dangerTint, fg: MF.danger, titleColor: MF.danger, chevron: false) {
                    confirmDelete = true
                },
            ])

            Text("MEDFLEET")
                .font(MFFont.logo(14)).tracking(6).foregroundStyle(MF.goldText)
                .frame(maxWidth: .infinity)
                .padding(.top, 32)
        }
        .alert("حذف الحساب", isPresented: $confirmDelete) {
            Button("حذف", role: .destructive) {
                Task {
                    guard !busy else { return }
                    busy = true
                    defer { busy = false }
                    do {
                        try await appState.api?.deleteBuyerAccount()
                        await appState.api?.logout()
                        tokenStore.clear()
                        store.user = nil
                        router.reset()
                    } catch {}
                }
            }
            Button("إلغاء", role: .cancel) {}
        } message: {
            Text("هذا إجراء نهائي لا يمكن التراجع عنه. هل أنت متأكد؟")
        }
    }

    private func group(_ rows: [SettingRow]) -> some View {
        GroupedList(rows) { r in
            ListRow(
                title: r.title,
                subtitle: r.subtitle,
                titleColor: r.titleColor,
                minHeight: 60,
                leading: AnyView(IconTile(systemImage: r.icon, bg: r.bg, fg: r.fg, size: 36, radius: 11)),
                trailing: r.chevron
                    ? AnyView(Image(systemName: "chevron.forward").font(.system(size: 12, weight: .semibold)).foregroundStyle(MF.ink3))
                    : nil,
                action: r.action
            )
        }
    }
}
