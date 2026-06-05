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
                    Text("متابعة المندوبين").font(.caption).foregroundStyle(.white.opacity(0.65))
                }

                VStack(spacing: 14) {
                    TextField("البريد الإلكتروني", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(MFColors.gold.opacity(0.3)))

                    HStack {
                        if showPassword {
                            TextField("كلمة المرور", text: $password)
                        } else {
                            SecureField("كلمة المرور", text: $password)
                        }
                        Button { showPassword.toggle() } label: {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundStyle(MFColors.gold)
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(MFColors.gold.opacity(0.3)))

                    if let error {
                        Text(error).font(.caption).foregroundStyle(MFColors.danger)
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
                        .padding(.vertical, 14)
                        .background(MFColors.gold)
                        .foregroundStyle(MFColors.navy)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(loading || email.isEmpty || password.isEmpty)
                }
                .padding(.horizontal, 28)

                Spacer()
            }
            .foregroundStyle(.white)
        }
        .environment(\.layoutDirection, .rightToLeft)
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
