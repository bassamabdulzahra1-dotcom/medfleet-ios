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
                colors: [MFColors.navy2, MFColors.navy, Color(red: 0.04, green: 0.07, blue: 0.09)],
                center: .center,
                startRadius: 20,
                endRadius: 500
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()
                VStack(spacing: 12) {
                    Circle()
                        .fill(LinearGradient(colors: [MFColors.goldDark, MFColors.gold], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 72, height: 72)
                        .overlay(Image(systemName: "location.fill").font(.title2).foregroundStyle(MFColors.navy))
                    Text("MedFleet").font(.title).bold().foregroundStyle(MFColors.gold)
                    Text("المشتريات").font(.caption).foregroundStyle(.white.opacity(0.65))
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
                                .tint(MFColors.gold)
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
                                .tint(MFColors.gold)
                                .textContentType(.password)
                            }
                            Button { showPassword.toggle() } label: {
                                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundStyle(MFColors.gold)
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
                            LinearGradient(colors: [MFColors.gold, MFColors.goldDark],
                                           startPoint: .top, endPoint: .bottom)
                        )
                        .foregroundStyle(MFColors.navy)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: MFColors.gold.opacity(0.35), radius: 10, y: 4)
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
                .foregroundStyle(MFColors.gold.opacity(0.9))
                .frame(width: 22)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(MFColors.gold.opacity(0.35), lineWidth: 1)
        )
    }

    private func login() async {
        loading = true
        error = nil
        defer { loading = false }
        guard let api = appState.api else { return }
        do {
            _ = try await api.login(email: email.trimmingCharacters(in: .whitespaces), password: password)
        } catch {
            self.error = error.localizedDescription
        }
    }
}
