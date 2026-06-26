import SwiftUI

struct SplashView: View {
    @State private var scale: CGFloat = 0.85
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [Color(red: 0.02, green: 0.09, blue: 0.18), Color(red: 0.04, green: 0.08, blue: 0.16), Color(red: 0.01, green: 0.04, blue: 0.11)],
                center: .center,
                startRadius: 20,
                endRadius: 500
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                SplashLogoView()
                    .frame(width: 180, height: 180)
                    .scaleEffect(scale)

                Text("MedFleet")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(Color(red: 0.57, green: 0.86, blue: 1.0))
                    .tracking(4)

                Text("المشتريات")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.75))
            }
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) { scale = 1; opacity = 1 }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }
}

private struct SplashLogoView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 44, style: .continuous)
                .fill(Color(red: 0.05, green: 0.12, blue: 0.2))

            Circle()
                .stroke(Color(red: 0.35, green: 0.75, blue: 1.0).opacity(0.12), lineWidth: 3)
                .frame(width: 146, height: 146)

            Circle()
                .stroke(Color(red: 0.4, green: 0.85, blue: 1.0).opacity(0.18), lineWidth: 3)
                .frame(width: 112, height: 112)

            SplashLogoShape()
                .fill(Color(red: 0.35, green: 0.75, blue: 1.0))
                .frame(width: 220, height: 220)
                .offset(y: -14)

            Circle()
                .fill(Color(red: 0.05, green: 0.12, blue: 0.2))
                .frame(width: 36, height: 36)
                .offset(y: -13)

            RoundedRectangle(cornerRadius: 6)
                .fill(Color(red: 0.05, green: 0.12, blue: 0.2))
                .frame(width: 30, height: 10)
                .offset(x: -6, y: -25)

            RoundedRectangle(cornerRadius: 6)
                .fill(Color(red: 0.05, green: 0.12, blue: 0.2))
                .frame(width: 10, height: 30)
                .offset(x: 5, y: -36)
        }
        .shadow(color: Color.blue.opacity(0.15), radius: 10, x: 0, y: 4)
    }
}

private struct SplashLogoShape: Shape {
    func path(in rect: CGRect) -> Path {
        let scale = rect.width / 1024
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: x * scale, y: y * scale)
        }

        var path = Path()
        path.move(to: p(512, 280))
        path.addCurve(to: p(360, 432), control1: p(428, 280), control2: p(360, 350))
        path.addCurve(to: p(506, 706), control1: p(360, 540), control2: p(496, 690))
        path.addQuadCurve(to: p(518, 706), control: p(512, 714))
        path.addCurve(to: p(664, 432), control1: p(528, 690), control2: p(664, 540))
        path.addCurve(to: p(512, 280), control1: p(664, 350), control2: p(596, 280))
        path.closeSubpath()
        return path
    }
}
