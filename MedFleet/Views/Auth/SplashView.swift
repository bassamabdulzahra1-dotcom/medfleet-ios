import SwiftUI

struct SplashView: View {
    @State private var logoProgress: CGFloat = 0
    @State private var textVisible = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.99, green: 0.98, blue: 0.97), Color(red: 0.95, green: 0.94, blue: 0.93)],
                startPoint: .top,
                endPoint: .bottom
            )
                .ignoresSafeArea()

            VStack(spacing: 18) {
                MedFleetLogoAnimationView(progress: logoProgress)
                    .frame(width: 220, height: 220)
                    .scaleEffect(0.9 + (0.1 * logoProgress))

                Text("MedFleet")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(MedFleetBrandPalette.plum)
                    .tracking(4)

                Text("المشتريات")
                    .font(.caption)
                    .foregroundColor(MedFleetBrandPalette.plum.opacity(0.72))
            }
            .opacity(textVisible ? 1 : 0)
            .offset(y: textVisible ? 0 : 10)
        }
        .onAppear {
            withAnimation(.interactiveSpring(response: 0.95, dampingFraction: 0.8, blendDuration: 0.15)) {
                logoProgress = 1
            }
            withAnimation(.easeOut(duration: 0.45).delay(0.42)) {
                textVisible = true
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }
}

struct MedFleetLogoAnimationView: View {
    let progress: CGFloat

    var body: some View {
        Image("BrandReference")
            .resizable()
            .scaledToFit()
            .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 10)
            .scaleEffect(0.92 + (0.08 * progress))
            .opacity(0.75 + (0.25 * progress))
    }
}

struct MedFleetLogoIconView: View {
    var body: some View {
        Image("BrandReference")
            .resizable()
            .scaledToFit()
            .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 8)
    }
}

enum MedFleetBrandPalette {
    static let plum = Color(red: 0.45, green: 0.25, blue: 0.45)
    static let plumDark = Color(red: 0.31, green: 0.16, blue: 0.31)
    static let ivory = Color(red: 0.98, green: 0.97, blue: 0.95)
}
