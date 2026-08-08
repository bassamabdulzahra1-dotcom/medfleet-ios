import SwiftUI

struct LoginView: View {
    @EnvironmentObject var tokenStore: TokenStore
    @EnvironmentObject var appState: AppState

    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var loading = false
    @State private var error: String?

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [Color(red: 0.06, green: 0.12, blue: 0.17), Color(red: 0.03, green: 0.08, blue: 0.12), Color(red: 0.01, green: 0.04, blue: 0.08)],
                center: .center,
                startRadius: 20,
                endRadius: 500
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()
                VStack(spacing: 12) {
                    Text("MedFleet")
                        .font(.title)
                        .bold()
                        .foregroundStyle(.white)
                    Text("المشتريات")
                        .font(.caption)
                        .foregroundStyle(Color(red: 0.63, green: 0.9, blue: 0.95))
                }

                VStack(spacing: 16) {
                    fieldShell(icon: "envelope.fill") {
                        ZStack(alignment: .trailing) {
                            if email.isEmpty {
                                Text("البريد الإلكتروني")
                                    .foregroundStyle(.white.opacity(0.45))
                            }
                            TextField("", text: $email)
                                .foregroundStyle(.white)
                                .tint(Color(red: 0.45, green: 0.89, blue: 0.95))
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                    }

                    fieldShell(icon: "lock.fill") {
                        HStack(spacing: 8) {
                            ZStack(alignment: .trailing) {
                                if password.isEmpty {
                                    Text("كلمة المرور")
                                        .foregroundStyle(.white.opacity(0.45))
                                }
                                Group {
                                    if showPassword {
                                        TextField("", text: $password)
                                    } else {
                                        SecureField("", text: $password)
                                    }
                                }
                                .foregroundStyle(.white)
                                .tint(Color(red: 0.45, green: 0.89, blue: 0.95))
                                .textContentType(.password)
                            }
                            Button { showPassword.toggle() } label: {
                                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundStyle(Color(red: 0.58, green: 0.92, blue: 0.97))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if let error {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(MFColors.danger)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }

                    Button {
                        Task { await login() }
                    } label: {
                        Group {
                            if loading {
                                ProgressView().tint(MFColors.navy)
                            } else {
                                Text("تسجيل الدخول").fontWeight(.bold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            LinearGradient(colors: [Color(red: 0.08, green: 0.68, blue: 0.8), Color(red: 0.01, green: 0.52, blue: 0.66)],
                                           startPoint: .top, endPoint: .bottom)
                        )
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: Color(red: 0.01, green: 0.52, blue: 0.66).opacity(0.35), radius: 12, y: 6)
                    }
                    .disabled(loading || email.isEmpty || password.isEmpty)
                    .opacity((loading || email.isEmpty || password.isEmpty) ? 0.55 : 1)
                    .padding(.top, 4)
                }
                .padding(.horizontal, 28)

                Spacer()
            }
            .foregroundStyle(.white)
        }
        .environment(\.layoutDirection, .rightToLeft)
    }

    @ViewBuilder
    private func fieldShell<Content: View>(icon: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 12) {
            content()
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color(red: 0.63, green: 0.92, blue: 0.97))
                .frame(width: 22)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .background(Color.white.opacity(0.09))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(red: 0.63, green: 0.92, blue: 0.97).opacity(0.28), lineWidth: 1)
        )
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
