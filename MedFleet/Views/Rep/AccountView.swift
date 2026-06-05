import SwiftUI

struct AccountView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var tokenStore: TokenStore
    @EnvironmentObject var appState: AppState

    var body: some View {
        OpenModuleLayout(onBack: { dismiss() }) {
            VStack(alignment: .trailing, spacing: 16) {
                Text("حسابي").font(.title2.bold()).padding(.top, 56)
                if let u = tokenStore.user {
                    Group {
                        row("الاسم", u.name)
                        row("البريد", u.email)
                        row("الدور", u.role == "sales_rep" ? "مندوب" : u.role)
                    }
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                Button(role: .destructive) {
                    Task {
                        await appState.api?.logout()
                        appState.cache.invalidateSuppliers()
                        appState.cache.invalidateSettlements()
                    }
                } label: {
                    Text("تسجيل الخروج").frame(maxWidth: .infinity).padding()
                }
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                Spacer()
            }
            .padding()
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(value).foregroundStyle(MFColors.navy)
            Spacer()
            Text(label).foregroundStyle(MFColors.muted).font(.caption)
        }
        .padding(.vertical, 4)
    }
}
