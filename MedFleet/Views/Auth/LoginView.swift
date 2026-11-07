import SwiftUI

struct LoginView: View {
    @EnvironmentObject var tokenStore: TokenStore
    @EnvironmentObject var appState: AppState

    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var loading = false
    @State private var error: String?
    @State private var showRecoverHint = false

    var body: some View {
        ZStack {
            MFColors.pine.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                Spacer()
                Text("M")
                    .font(.system(size: 44, weight: .regular, design: .serif))
                    .foregroundStyle(MFColors.pine)
                    .frame(width: 84, height: 84)
                    .background(MFColors.gold, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                Text("MEDFLEET")
                    .font(.system(size: 30, weight: .regular, design: .serif))
                    .tracking(10)
                    .foregroundStyle(MFColors.gold)
                    .environment(\.layoutDirection, .leftToRight)
                    .padding(.top, 22)
                Text("إدارة الصيدلية بأناقة —\nالمخزن، الفواتير، والفريق في مكان واحد.")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.white.opacity(0.72))
                    .lineSpacing(6)
                    .padding(.top, 14)

                field(text: $email, placeholder: "البريد الإلكتروني أو اسم المستخدم", isSecure: false)
                    .padding(.top, 28)
                field(text: $password, placeholder: "كلمة المرور", isSecure: !showPassword)
                    .overlay(alignment: .leading) {
                        Button { showPassword.toggle() } label: {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundStyle(MFColors.gold.opacity(0.85))
                                .padding(14)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 12)

                if let error {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(Color(red: 232/255, green: 154/255, blue: 134/255))
                        .frame(maxWidth: .infinity)
                        .padding(.top, 12)
                }

                Spacer()
                Button {
                    Task { await login() }
                } label: {
                    Group {
                        if loading {
                            ProgressView().tint(MFColors.pine)
                        } else {
                            Text("دخول")
                                .font(.system(size: 16, weight: .bold))
                        }
                    }
                    .foregroundStyle(MFColors.pine)
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(MFColors.gold, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .disabled(loading || email.isEmpty || password.isEmpty)
                .opacity((loading || email.isEmpty || password.isEmpty) ? 0.55 : 1)
            }
            .padding(28)
        }
        .environment(\.layoutDirection, .rightToLeft)
        .preferredColorScheme(.dark)
        .alert("استعادة الحساب", isPresented: $showRecoverHint) {
            Button("حسناً", role: .cancel) {}
        } message: {
            Text("لاستعادة الحساب تواصل مع الإدارة.")
        }
    }

    private func field(text: Binding<String>, placeholder: String, isSecure: Bool) -> some View {
        ZStack(alignment: .trailing) {
            if text.wrappedValue.isEmpty {
                Text(placeholder)
                    .foregroundStyle(Color.white.opacity(0.55))
                    .font(.system(size: 14))
                    .padding(.horizontal, 18)
            }
            Group {
                if isSecure {
                    SecureField("", text: text)
                } else {
                    TextField("", text: text)
                }
            }
            .foregroundStyle(.white)
            .font(.system(size: 15))
            .tint(MFColors.gold)
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
            .padding(.horizontal, 18)
            .padding(.trailing, isSecure ? 28 : 0)
        }
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(MFColors.gold.opacity(0.2), lineWidth: 1)
        )
        .onChange(of: text.wrappedValue, perform: { _ in error = nil })
    }

    private func login() async {
        loading = true
        error = nil
        defer { loading = false }
        guard let api = appState.api else { return }
        do {
            let res = try await api.login(email: email.trimmingCharacters(in: .whitespaces), password: password)
            if res.user.role != "buyer" {
                tokenStore.clear()
                self.error = "هذا الحساب غير مسموح بالدخول من التطبيق"
            }
        } catch {
            self.error = error.localizedDescription
        }
    }
}
