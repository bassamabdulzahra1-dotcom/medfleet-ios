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
                colors: [Color(red: 0.22, green: 0.12, blue: 0.22), Color(red: 0.13, green: 0.08, blue: 0.15), Color(red: 0.07, green: 0.05, blue: 0.08)],
                center: .center,
                startRadius: 20,
                endRadius: 500
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()
                VStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(MedFleetBrandPalette.ivory)
                            .frame(width: 112, height: 112)

                        MedFleetLogoIconView()
                            .frame(width: 84, height: 84)
                    }
                    .shadow(color: Color.black.opacity(0.16), radius: 18, y: 8)

                    Text("MedFleet")
                        .font(.title)
                        .bold()
                        .foregroundStyle(MedFleetBrandPalette.ivory)
                    Text("المشتريات")
                        .font(.caption)
                        .foregroundStyle(MedFleetBrandPalette.ivory.opacity(0.76))
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
                                .tint(MedFleetBrandPalette.ivory)
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
                                .tint(MedFleetBrandPalette.ivory)
                                .textContentType(.password)
                            }
                            Button { showPassword.toggle() } label: {
                                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundStyle(MedFleetBrandPalette.ivory)
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
                            LinearGradient(colors: [MedFleetBrandPalette.plum, MedFleetBrandPalette.plumDark],
                                           startPoint: .top, endPoint: .bottom)
                        )
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: MedFleetBrandPalette.plumDark.opacity(0.35), radius: 12, y: 6)
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
                .foregroundStyle(MedFleetBrandPalette.ivory.opacity(0.92))
                .frame(width: 22)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .background(Color.white.opacity(0.09))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(MedFleetBrandPalette.ivory.opacity(0.26), lineWidth: 1)
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
