import SwiftUI

struct SplashView: View {
    private let onFinished: () -> Void

    init(onFinished: @escaping () -> Void = {}) {
        self.onFinished = onFinished
    }

    var body: some View {
        PlatinumSplashView(onFinished: onFinished)
    }
}

private struct PlatinumSplashView: View {
    private let onFinished: () -> Void
    private let letters: [(String, Double)] = [
        ("M", 0.20), ("E", 0.35), ("D", 0.50), ("F", 0.65),
        ("L", 0.80), ("E", 0.95), ("E", 1.10), ("T", 1.25)
    ]

    @State private var showLetters = false
    @State private var showDivider = false
    @State private var didFinish = false

    init(onFinished: @escaping () -> Void) {
        self.onFinished = onFinished
    }

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

            VStack(spacing: 15) {
                HStack(spacing: 4) {
                    ForEach(Array(letters.enumerated()), id: \.offset) { _, item in
                        Text(item.0)
                            .font(.system(size: 44, weight: .bold, design: .default))
                            .foregroundStyle(platinumText)
                            .opacity(showLetters ? 1 : 0)
                            .offset(y: showLetters ? 0 : 30)
                            .scaleEffect(showLetters ? 1 : 0.8)
                            .animation(
                                .spring(response: 0.55, dampingFraction: 0.72).delay(item.1),
                                value: showLetters
                            )
                    }
                }
                .environment(\.layoutDirection, .leftToRight)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.clear, Color(red: 203/255, green: 213/255, blue: 225/255), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 70, height: 3)
                    .scaleEffect(x: showDivider ? 1 : 0, y: 1, anchor: .center)
                    .opacity(showDivider ? 1 : 0)
                    .animation(.easeOut(duration: 1.0), value: showDivider)
            }
        }
        .onAppear {
            showLetters = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                showDivider = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
                guard !didFinish else { return }
                didFinish = true
                onFinished()
            }
        }
    }

    private var platinumText: LinearGradient {
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
}
