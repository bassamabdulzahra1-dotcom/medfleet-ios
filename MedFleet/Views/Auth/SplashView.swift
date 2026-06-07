import SwiftUI

struct SplashView: View {
    @State private var scale: CGFloat = 0.85
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [MFColors.navy2, MFColors.navy, Color(red: 0.04, green: 0.07, blue: 0.09)],
                center: .center,
                startRadius: 20,
                endRadius: 500
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                Circle()
                    .fill(LinearGradient(colors: [MFColors.goldDark, MFColors.gold], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 80, height: 80)
                    .overlay(Image(systemName: "location.fill").font(.title).foregroundStyle(MFColors.navy))
                    .scaleEffect(scale)

                Text("MedFleet")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(MFColors.gold)
                    .tracking(4)

                Text("المشتريات")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))
            }
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) { scale = 1; opacity = 1 }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }
}
