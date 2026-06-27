import SwiftUI

struct BuyerSettingsView: View {
    @EnvironmentObject var tokenStore: TokenStore
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var showDeleteConfirm = false
    @State private var deleting = false
    @State private var loggingOut = false
    @State private var error: String?

    private var roleLabel: String {
        switch tokenStore.user?.role {
        case "buyer": return "مشتري (صيدلية)"
        case "sales_rep": return "مندوب مبيعات"
        case "admin": return "مدير"
        default: return tokenStore.user?.role ?? "—"
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .trailing, spacing: 14) {
                header

                accountCard

                privacyCard

                logoutCard

                dangerCard

                if let error {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(MFColors.danger)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
        }
        .background(LinearGradient(colors: [MFColors.bgTop, MFColors.bgBottom], startPoint: .top, endPoint: .bottom).ignoresSafeArea())
        .environment(\.layoutDirection, .rightToLeft)
        .alert("حذف الحساب نهائياً", isPresented: $showDeleteConfirm) {
            Button("إلغاء", role: .cancel) {}
            Button("حذف", role: .destructive) { Task { await deleteAccount() } }
        } message: {
            Text("سيتم حذف حسابك وبياناتك الشخصية نهائياً ولا يمكن التراجع عن هذا الإجراء.")
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(MFColors.navy)
                    .frame(width: 40, height: 40)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.06), radius: 3, y: 1)
            }
            Spacer()
            Text("الإعدادات")
                .font(.headline)
                .foregroundStyle(MFColors.navy)
        }
        .padding(.top, 6)
    }

    // MARK: - Account info

    private var accountCard: some View {
        VStack(alignment: .trailing, spacing: 10) {
            Text("بيانات الحساب")
                .font(.subheadline.bold())
                .foregroundStyle(MFColors.navy)
                .frame(maxWidth: .infinity, alignment: .trailing)

            infoRow(label: "الاسم", value: tokenStore.user?.name ?? "—")
            Divider()
            infoRow(label: "البريد الإلكتروني", value: tokenStore.user?.email ?? "—")
            Divider()
            infoRow(label: "نوع الحساب", value: roleLabel)
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(MFColors.navy)
                .multilineTextAlignment(.trailing)
            Spacer()
            Text(label)
                .font(.caption)
                .foregroundStyle(MFColors.muted)
        }
    }

    // MARK: - Privacy policy

    private var privacyCard: some View {
        VStack(alignment: .trailing, spacing: 12) {
            HStack {
                Spacer()
                Image(systemName: "lock.shield.fill").foregroundStyle(MFColors.accentDark)
                Text("سياسة الخصوصية")
                    .font(.subheadline.bold())
                    .foregroundStyle(MFColors.navy)
            }

            if let url = URL(string: "https://medfleet.net/privacy") {
                Link(destination: url) {
                    HStack {
                        Image(systemName: "chevron.left")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(MFColors.muted)
                        Spacer()
                        Text("عرض سياسة الخصوصية")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(MFColors.navy)
                        Image(systemName: "safari")
                            .foregroundStyle(MFColors.accentDark)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    // MARK: - Logout

    private var logoutCard: some View {
        Button {
            Task { await logout() }
        } label: {
            HStack {
                if loggingOut { ProgressView().tint(MFColors.navy) }
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text(loggingOut ? "جاري الخروج…" : "تسجيل الخروج")
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(Color.white)
            .foregroundStyle(MFColors.navy)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(MFColors.accent.opacity(0.45), lineWidth: 1))
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        }
        .disabled(loggingOut)
        .opacity(loggingOut ? 0.6 : 1)
    }

    // MARK: - Danger zone (delete account)

    private var dangerCard: some View {
        VStack(alignment: .trailing, spacing: 10) {
            Text("منطقة الخطر")
                .font(.subheadline.bold())
                .foregroundStyle(MFColors.danger)
                .frame(maxWidth: .infinity, alignment: .trailing)

            Text("حذف الحساب إجراء نهائي لا يمكن التراجع عنه.")
                .font(.caption)
                .foregroundStyle(MFColors.muted)
                .frame(maxWidth: .infinity, alignment: .trailing)

            Button {
                error = nil
                showDeleteConfirm = true
            } label: {
                HStack {
                    if deleting { ProgressView().tint(.white) }
                    Image(systemName: "trash.fill")
                    Text(deleting ? "جاري الحذف…" : "حذف الحساب")
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(MFColors.danger)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(deleting)
            .opacity(deleting ? 0.6 : 1)
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(MFColors.danger.opacity(0.3), lineWidth: 1))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    // MARK: - Actions

    private func logout() async {
        loggingOut = true
        defer { loggingOut = false }
        await appState.api?.logout()
        tokenStore.clear()
    }

    private func deleteAccount() async {
        guard let api = appState.api else { return }
        deleting = true
        error = nil
        defer { deleting = false }
        do {
            try await api.deleteBuyerAccount()
            // تسجيل الخروج بعد الحذف → العودة لشاشة الدخول
            tokenStore.clear()
        } catch let err {
            if let apiErr = err as? APIError, case let .http(_, msg) = apiErr {
                self.error = msg ?? "تعذّر حذف الحساب. حاول لاحقاً."
            } else {
                self.error = "تعذّر الاتصال بالخادم."
            }
        }
    }
}
