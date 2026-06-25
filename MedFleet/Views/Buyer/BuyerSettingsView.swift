import SwiftUI

struct BuyerSettingsView: View {
    @EnvironmentObject var tokenStore: TokenStore
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var showDeleteConfirm = false
    @State private var deleting = false
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
        VStack(alignment: .trailing, spacing: 10) {
            HStack {
                Spacer()
                Image(systemName: "lock.shield.fill").foregroundStyle(MFColors.gold)
                Text("سياسة الخصوصية")
                    .font(.subheadline.bold())
                    .foregroundStyle(MFColors.navy)
            }

            policyParagraph(
                title: "البيانات التي نجمعها",
                body: "نجمع اسمك وبريدك الإلكتروني ونوع حسابك لتسجيل الدخول وتشغيل التطبيق. وعند استخدام ماسحة الفاتورة نعالج صور الفواتير التي تلتقطها لاستخراج بيانات الأصناف فقط."
            )
            policyParagraph(
                title: "كيف نستخدم بياناتك",
                body: "تُستخدم بياناتك حصراً لتشغيل ميزات التطبيق: استعراض المخزن، مسح الفواتير، وإنشاء مسوّدات الشراء. لا نبيع بياناتك ولا نشاركها مع أي طرف ثالث لأغراض تسويقية."
            )
            policyParagraph(
                title: "صور الفواتير",
                body: "تُرفع صور الفواتير إلى خادمنا وتُعالَج عبر خدمة ذكاء اصطناعي لاستخراج النصوص فقط، ثم تُحفظ مرتبطة بمسوّدة الشراء الخاصة بك."
            )
            policyParagraph(
                title: "الاحتفاظ والحذف",
                body: "يمكنك حذف حسابك نهائياً في أي وقت من هذه الصفحة. عند الحذف تُزال بياناتك الشخصية (الاسم والبريد) ويُلغى ارتباط سجلاتك بحسابك."
            )
            policyParagraph(
                title: "الأمان والتواصل",
                body: "جميع الاتصالات مشفّرة عبر HTTPS والوصول محمي برمز دخول. لأي استفسار حول الخصوصية تواصل معنا على support@medfleet.net."
            )

            if let url = URL(string: "https://medfleet.net/privacy") {
                Link(destination: url) {
                    HStack(spacing: 6) {
                        Image(systemName: "safari")
                        Text("عرض السياسة الكاملة على الويب")
                            .fontWeight(.semibold)
                    }
                    .font(.caption)
                    .foregroundStyle(MFColors.goldDark)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.top, 4)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private func policyParagraph(title: String, body: String) -> some View {
        VStack(alignment: .trailing, spacing: 3) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(MFColors.goldDark)
                .frame(maxWidth: .infinity, alignment: .trailing)
            Text(body)
                .font(.caption)
                .foregroundStyle(MFColors.muted)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
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
