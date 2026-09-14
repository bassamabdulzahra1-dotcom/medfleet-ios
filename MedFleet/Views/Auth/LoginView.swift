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
            LinearGradient(
                colors: [
                    Color(red: 20/255, green: 22/255, blue: 24/255),
                    Color(red: 34/255, green: 38/255, blue: 43/255),
                    Color(red: 13/255, green: 15/255, blue: 17/255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Text("MEDFLEET")
                        .font(.system(size: 32, weight: .bold))
                        .tracking(6)
                        .foregroundStyle(platinumTitle)
                        .padding(.leading, 6)
                        .environment(\.layoutDirection, .leftToRight)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.clear, Color(red: 203/255, green: 213/255, blue: 225/255), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 60, height: 3)
                        .shadow(color: Color(red: 203/255, green: 213/255, blue: 225/255).opacity(0.4), radius: 8)
                        .padding(.top, 6)
                        .padding(.bottom, 40)

                    field(
                        text: $email,
                        placeholder: "البريد الإلكتروني أو اسم المستخدم",
                        isSecure: false
                    )
                    .padding(.bottom, 20)

                    field(
                        text: $password,
                        placeholder: "كلمة المرور",
                        isSecure: !showPassword
                    )
                    .overlay(alignment: .leading) {
                        Button { showPassword.toggle() } label: {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Color(red: 203/255, green: 213/255, blue: 225/255).opacity(0.7))
                                .padding(14)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.bottom, 10)

                    if let error {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(Color(red: 248/255, green: 113/255, blue: 113/255))
                            .frame(maxWidth: .infinity)
                            .padding(.bottom, 8)
                    }

                    Button {
                        Task { await login() }
                    } label: {
                        Group {
                            if loading {
                                ProgressView().tint(Color(red: 203/255, green: 213/255, blue: 225/255))
                            } else {
                                Text("تسجيل الدخول")
                                    .font(.system(size: 16, weight: .semibold))
                                    .tracking(1)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .foregroundStyle(Color(red: 203/255, green: 213/255, blue: 225/255))
                        .background(
                            LinearGradient(
                                colors: [Color(red: 42/255, green: 46/255, blue: 53/255), Color(red: 26/255, green: 28/255, blue: 35/255)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: .black.opacity(0.3), radius: 10, y: 4)
                    }
                    .disabled(loading || email.isEmpty || password.isEmpty)
                    .opacity((loading || email.isEmpty || password.isEmpty) ? 0.55 : 1)
                    .padding(.top, 10)

                    HStack(spacing: 4) {
                        Text("نسيت كلمة المرور؟")
                            .foregroundStyle(Color(red: 100/255, green: 116/255, blue: 139/255))
                        Button("استعادة الحساب") {
                            showRecoverHint = true
                        }
                        .foregroundStyle(Color(red: 203/255, green: 213/255, blue: 225/255))
                    }
                    .font(.system(size: 13))
                    .padding(.top, 30)
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 28)
                .frame(maxWidth: 380)
                .frame(maxWidth: .infinity)
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .alert("استعادة الحساب", isPresented: $showRecoverHint) {
            Button("حسناً", role: .cancel) {}
        } message: {
            Text("لاستعادة الحساب تواصل مع الإدارة.")
        }
    }

    private var platinumTitle: LinearGradient {
        LinearGradient(
            colors: [
                .white,
                Color(red: 203/255, green: 213/255, blue: 225/255),
                Color(red: 100/255, green: 116/255, blue: 139/255)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func field(text: Binding<String>, placeholder: String, isSecure: Bool) -> some View {
        ZStack(alignment: .trailing) {
            if text.wrappedValue.isEmpty {
                Text(placeholder)
                    .foregroundStyle(Color(red: 113/255, green: 113/255, blue: 122/255))
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
            .foregroundStyle(Color(red: 243/255, green: 244/255, blue: 246/255))
            .font(.system(size: 15))
            .tint(Color(red: 203/255, green: 213/255, blue: 225/255))
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
            .padding(.horizontal, 18)
            .padding(.trailing, isSecure ? 28 : 0)
        }
        .padding(.vertical, 16)
        .background(Color(red: 17/255, green: 19/255, blue: 21/255).opacity(0.65))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(red: 203/255, green: 213/255, blue: 225/255).opacity(0.12), lineWidth: 1)
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
