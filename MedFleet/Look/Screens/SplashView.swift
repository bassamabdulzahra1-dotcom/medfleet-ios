import SwiftUI

/// الشاشة الافتتاحية المتحركة (4.7 ثانية):
/// 1) الخلفية والدوائر الذهبية  2) Medfleet تنكتب بالقلم  3) Pharmacy + الخطّين  4) لمعة ذهبية
/// ثم onFinish().
struct SplashView: View {
    let onFinish: () -> Void
    @State private var start = Date()

    private static let gold = LinearGradient(
        stops: [
            .init(color: Color(hex: 0xF1DCA8), location: 0),
            .init(color: Color(hex: 0xC9A96E), location: 0.5),
            .init(color: Color(hex: 0xEAD9B2), location: 1),
        ],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    private static let cream = Color(hex: 0xFFF6DD)

    var body: some View {
        TimelineView(.animation) { ctx in
            let t = ctx.date.timeIntervalSince(start)
            GeometryReader { geo in
                scene(t: t, size: geo.size)
            }
        }
        .ignoresSafeArea()
        .environment(\.layoutDirection, .leftToRight)
        .preferredColorScheme(.dark)
        .onAppear { start = Date() }
        .task {
            try? await Task.sleep(nanoseconds: 4_700_000_000)
            onFinish()
        }
    }

    // MARK: - المشهد

    private func scene(t: Double, size: CGSize) -> some View {
        let w = size.width
        let bgIn = eOut(t / 0.5)
        let rings = eOut((t - 0.1) / 1.4)
        let write = eInOut((t - 0.45) / 2.1)
        let ph = eOut((t - 2.35) / 0.8)
        let lines = eOut((t - 2.6) / 0.7)
        let shine = eInOut((t - 3.35) / 1.0)
        let logoW = w * 0.8

        return ZStack {
            MF.pine
            RadialGradient(colors: [Color(hex: 0x11695B, alpha: 0.55), .clear],
                           center: UnitPoint(x: 0.5, y: 0.42), startRadius: 0, endRadius: w * 0.9)
            Canvas { g, s in
                let u = s.width / 1024
                let k = 0.72 + 0.28 * rings
                let c = CGPoint(x: -60 * u, y: s.height + 60 * u)
                for i in 0..<11 {
                    let r = (150 + 92 * CGFloat(i)) * u * k
                    g.stroke(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)),
                             with: .color(MF.gold.opacity(0.17 * rings)), lineWidth: 3 * u)
                }
            }

            VStack(spacing: 18) {
                medfleet(width: logoW, write: write, shine: shine)
                HStack(spacing: 14) {
                    sideLine(lines, alignTrailing: true)
                    goldImage("pharmacy_script", width: 150, aspect: 694.0 / 189.0)
                        .overlay(shineBand(shine).mask(script("pharmacy_script")))
                    sideLine(lines, alignTrailing: false)
                }
                .opacity(ph)
                .offset(y: (1 - ph) * 16)
            }
        }
        .opacity(0.35 + 0.65 * bgIn)
    }

    private func script(_ name: String) -> some View {
        Image(name).resizable().scaledToFit()
    }

    private func goldImage(_ name: String, width: CGFloat, aspect: CGFloat) -> some View {
        Rectangle().fill(Self.gold)
            .mask(script(name))
            .frame(width: width, height: width / aspect)
    }

    /// Medfleet مع كشف الكتابة بحافة مائلة + لمعة رأس القلم + اللمعة العابرة
    private func medfleet(width: CGFloat, write p: Double, shine: Double) -> some View {
        let aspect: CGFloat = 1290.0 / 423.0
        let h = width / aspect
        let feather = 0.03 * width
        let len = (1 + 0.35 * 0.35).squareRoot()
        let n = CGPoint(x: 1 / len, y: 0.35 / len)
        let ex = -0.06 * width + CGFloat(p) * 1.12 * width
        let ey = h / 2
        func unit(_ dx: CGFloat) -> UnitPoint {
            UnitPoint(x: (ex + n.x * dx) / width, y: (ey + n.y * dx) / h)
        }

        return goldImage("medfleet_script", width: width, aspect: aspect)
            .overlay(
                ZStack {
                    if p > 0 && p < 1 {
                        LinearGradient(stops: [
                            .init(color: .clear, location: 0),
                            .init(color: Self.cream.opacity(0.9), location: 0.5),
                            .init(color: .clear, location: 1),
                        ], startPoint: unit(-feather * 1.4), endPoint: unit(feather * 0.6))
                    }
                    shineBand(shine)
                }
                .mask(script("medfleet_script"))
            )
            .mask(
                LinearGradient(colors: [.white, .clear], startPoint: unit(-feather), endPoint: unit(feather))
            )
            .accessibilityLabel("Medfleet")
    }

    @ViewBuilder
    private func shineBand(_ q: Double) -> some View {
        if q > 0 && q < 1 {
            let x = -0.3 + q * 1.6
            LinearGradient(stops: [
                .init(color: .clear, location: 0),
                .init(color: Self.cream.opacity(0.8), location: 0.5),
                .init(color: .clear, location: 1),
            ], startPoint: UnitPoint(x: x - 0.08, y: -0.15), endPoint: UnitPoint(x: x + 0.08, y: 0.15))
        }
    }

    private func sideLine(_ progress: Double, alignTrailing: Bool) -> some View {
        ZStack(alignment: alignTrailing ? .trailing : .leading) {
            Color.clear
            Capsule().fill(MF.gold).frame(width: 44 * max(progress, 0.001))
        }
        .frame(width: 44, height: 2)
    }

    // MARK: - منحنيات الحركة

    private func clamp(_ x: Double) -> Double { min(max(x, 0), 1) }
    private func eOut(_ x: Double) -> Double { let v = clamp(x); return 1 - pow(1 - v, 3) }
    private func eInOut(_ x: Double) -> Double { let v = clamp(x); return v * v * (3 - 2 * v) }
}

#Preview("الافتتاحية المتحركة") {
    SplashView {}
}
