import SwiftUI

struct SplashView: View {
    private let onFinished: () -> Void

    init(onFinished: @escaping () -> Void = {}) {
        self.onFinished = onFinished
    }

    var body: some View {
        CapsuleSplashView(onFinished: onFinished)
        .environment(\.layoutDirection, .rightToLeft)
    }
}

// MARK: - Capsule splash animation

private let brandTeal = Color(red: 4/255, green: 157/255, blue: 191/255)
private let designSize: CGFloat = 1024

private enum Piece: CaseIterable {
    case top, bottom, left, right
}

private enum Corner { case topLeft, topRight, bottomRight, bottomLeft }

private struct PieceGeometry {
    let finalCenter: CGPoint
    let finalCorner: Corner
    let startCenter: CGPoint
    let poppedCenter: CGPoint
    let controlPoint: CGPoint
    let localSize: CGSize
    let roundedCorners: (Corner, Corner)
}

private let R: CGFloat = 106
private let finalBoxSize = CGSize(width: 2 * R, height: 2 * R)
private let Wt: CGFloat = 172
private let Lh: CGFloat = 142

private let geometry: [Piece: PieceGeometry] = [
    .top: PieceGeometry(
        finalCenter: CGPoint(x: 483, y: 323), finalCorner: .topLeft,
        startCenter: CGPoint(x: 585, y: 344), poppedCenter: CGPoint(x: 585, y: 318),
        controlPoint: CGPoint(x: 532.4, y: 287.9),
        localSize: CGSize(width: Wt, height: Lh),
        roundedCorners: (.topLeft, .topRight)
    ),
    .bottom: PieceGeometry(
        finalCenter: CGPoint(x: 533, y: 699), finalCorner: .bottomRight,
        startCenter: CGPoint(x: 585, y: 486), poppedCenter: CGPoint(x: 585, y: 512),
        controlPoint: CGPoint(x: 499.2, y: 588.9),
        localSize: CGSize(width: Wt, height: Lh),
        roundedCorners: (.bottomLeft, .bottomRight)
    ),
    .left: PieceGeometry(
        finalCenter: CGPoint(x: 321, y: 480), finalCorner: .topLeft,
        startCenter: CGPoint(x: 344, y: 600), poppedCenter: CGPoint(x: 318, y: 600),
        controlPoint: CGPoint(x: 357.9, y: 541.0),
        localSize: CGSize(width: Lh, height: Wt),
        roundedCorners: (.topLeft, .bottomLeft)
    ),
    .right: PieceGeometry(
        finalCenter: CGPoint(x: 701, y: 535), finalCorner: .bottomRight,
        startCenter: CGPoint(x: 486, y: 600), poppedCenter: CGPoint(x: 512, y: 600),
        controlPoint: CGPoint(x: 627.3, y: 628.0),
        localSize: CGSize(width: Lh, height: Wt),
        roundedCorners: (.topRight, .bottomRight)
    ),
]

private struct Timing {
    static let closedHold: Double = 0.30
    static let popOpen: Double = 0.30
    static let arcMove: Double = 1.20
    static let finalHold: Double = 1.00
    static let fadeOut: Double = 0.20

    static let popStart = closedHold
    static let arcStart = closedHold + popOpen
    static let arcEnd = arcStart + arcMove
    static let holdEnd = arcEnd + finalHold
    static let totalEnd = holdEnd + fadeOut
}

private func easeInOutCubic(_ t: Double) -> Double {
    let t = min(max(t, 0), 1)
    return t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3) / 2
}

private func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat { a + (b - a) * t }

private func lerpPoint(_ a: CGPoint, _ b: CGPoint, _ t: CGFloat) -> CGPoint {
    CGPoint(x: lerp(a.x, b.x, t), y: lerp(a.y, b.y, t))
}

private func quadBezier(_ p0: CGPoint, _ pc: CGPoint, _ p1: CGPoint, _ t: CGFloat) -> CGPoint {
    let mt = 1 - t
    let x = mt * mt * p0.x + 2 * mt * t * pc.x + t * t * p1.x
    let y = mt * mt * p0.y + 2 * mt * t * pc.y + t * t * p1.y
    return CGPoint(x: x, y: y)
}

private struct PieceFrame {
    var rect: CGRect
    var radii: (topLeft: CGFloat, topRight: CGFloat, bottomRight: CGFloat, bottomLeft: CGFloat)
}

private func radii(for corners: (Corner, Corner), radius: CGFloat) -> (CGFloat, CGFloat, CGFloat, CGFloat) {
    var tl: CGFloat = 0
    var tr: CGFloat = 0
    var br: CGFloat = 0
    var bl: CGFloat = 0
    for c in [corners.0, corners.1] {
        switch c {
        case .topLeft: tl = radius
        case .topRight: tr = radius
        case .bottomRight: br = radius
        case .bottomLeft: bl = radius
        }
    }
    return (tl, tr, br, bl)
}

private func finalRadii(for corner: Corner, radius: CGFloat) -> (CGFloat, CGFloat, CGFloat, CGFloat) {
    var tl: CGFloat = 0
    var tr: CGFloat = 0
    var br: CGFloat = 0
    var bl: CGFloat = 0
    switch corner {
    case .topLeft: tl = radius
    case .topRight: tr = radius
    case .bottomRight: br = radius
    case .bottomLeft: bl = radius
    }
    return (tl, tr, br, bl)
}

private func frame(for piece: Piece, elapsed: Double) -> PieceFrame {
    let g = geometry[piece]!
    let center: CGPoint
    let shapeT: CGFloat

    switch elapsed {
    case ..<Timing.popStart:
        center = g.startCenter
        shapeT = 0
    case Timing.popStart..<Timing.arcStart:
        let local = (elapsed - Timing.popStart) / Timing.popOpen
        let te = CGFloat(easeInOutCubic(local))
        center = lerpPoint(g.startCenter, g.poppedCenter, te)
        shapeT = 0
    case Timing.arcStart..<Timing.arcEnd:
        let local = (elapsed - Timing.arcStart) / Timing.arcMove
        let te = CGFloat(easeInOutCubic(local))
        center = quadBezier(g.poppedCenter, g.controlPoint, g.finalCenter, te)
        shapeT = te
    default:
        center = g.finalCenter
        shapeT = 1
    }

    let startRadii = radii(for: g.roundedCorners, radius: min(g.localSize.width, g.localSize.height) / 2)
    let endRadii = finalRadii(for: g.finalCorner, radius: R)

    let size = CGSize(
        width: lerp(g.localSize.width, finalBoxSize.width, shapeT),
        height: lerp(g.localSize.height, finalBoxSize.height, shapeT)
    )
    let rect = CGRect(
        x: center.x - size.width / 2,
        y: center.y - size.height / 2,
        width: size.width,
        height: size.height
    )

    let tl = lerp(startRadii.0, endRadii.0, shapeT)
    let tr = lerp(startRadii.1, endRadii.1, shapeT)
    let br = lerp(startRadii.2, endRadii.2, shapeT)
    let bl = lerp(startRadii.3, endRadii.3, shapeT)

    return PieceFrame(rect: rect, radii: (tl, tr, br, bl))
}

private func path(for frame: PieceFrame) -> Path {
    let r = frame.rect
    let tl = min(frame.radii.topLeft, r.width / 2, r.height / 2)
    let tr = min(frame.radii.topRight, r.width / 2, r.height / 2)
    let br = min(frame.radii.bottomRight, r.width / 2, r.height / 2)
    let bl = min(frame.radii.bottomLeft, r.width / 2, r.height / 2)

    var p = Path()
    p.move(to: CGPoint(x: r.minX + tl, y: r.minY))
    p.addLine(to: CGPoint(x: r.maxX - tr, y: r.minY))
    p.addArc(
        center: CGPoint(x: r.maxX - tr, y: r.minY + tr),
        radius: tr,
        startAngle: .degrees(-90),
        endAngle: .degrees(0),
        clockwise: false
    )
    p.addLine(to: CGPoint(x: r.maxX, y: r.maxY - br))
    p.addArc(
        center: CGPoint(x: r.maxX - br, y: r.maxY - br),
        radius: br,
        startAngle: .degrees(0),
        endAngle: .degrees(90),
        clockwise: false
    )
    p.addLine(to: CGPoint(x: r.minX + bl, y: r.maxY))
    p.addArc(
        center: CGPoint(x: r.minX + bl, y: r.maxY - bl),
        radius: bl,
        startAngle: .degrees(90),
        endAngle: .degrees(180),
        clockwise: false
    )
    p.addLine(to: CGPoint(x: r.minX, y: r.minY + tl))
    p.addArc(
        center: CGPoint(x: r.minX + tl, y: r.minY + tl),
        radius: tl,
        startAngle: .degrees(180),
        endAngle: .degrees(270),
        clockwise: false
    )
    p.closeSubpath()
    return p
}

public struct CapsuleSplashView: View {
    private let onFinished: () -> Void
    @State private var startDate = Date()
    @State private var didFinish = false

    public init(onFinished: @escaping () -> Void) {
        self.onFinished = onFinished
    }

    public var body: some View {
        GeometryReader { proxy in
            let scale = min(proxy.size.width, proxy.size.height) / designSize
            let offsetX = (proxy.size.width - designSize * scale) / 2
            let offsetY = (proxy.size.height - designSize * scale) / 2

            TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: false)) { context in
                let elapsed = context.date.timeIntervalSince(startDate)
                let fadeT = elapsed > Timing.holdEnd
                    ? CGFloat(min((elapsed - Timing.holdEnd) / Timing.fadeOut, 1))
                    : 0

                ZStack {
                    brandTeal.ignoresSafeArea()

                    Canvas { gc, _ in
                        gc.translateBy(x: offsetX, y: offsetY)
                        gc.scaleBy(x: scale, y: scale)
                        for piece in Piece.allCases {
                            let frame = frame(for: piece, elapsed: elapsed)
                            gc.fill(path(for: frame), with: .color(.white))
                        }
                    }

                    Color.white.opacity(fadeT).ignoresSafeArea()
                }
                .onChange(of: elapsed >= Timing.totalEnd) { isDone in
                    if isDone && !didFinish {
                        didFinish = true
                        onFinished()
                    }
                }
            }
        }
        .onAppear { startDate = Date() }
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
