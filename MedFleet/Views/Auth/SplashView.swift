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
        ZStack {
            RoundedRectangle(cornerRadius: 56, style: .continuous)
                .fill(Color.white.opacity(0.32))
                .frame(width: 208, height: 208)
                .overlay {
                    RoundedRectangle(cornerRadius: 56, style: .continuous)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                }
                .blur(radius: 0.2)

            MedFleetLogoMarkView(progress: progress)
                .scaleEffect(0.84)
        }
    }
}

struct MedFleetLogoIconView: View {
    var body: some View {
        MedFleetLogoMarkView(progress: 1)
            .scaleEffect(0.64)
    }
}

enum MedFleetBrandPalette {
    static let plum = Color(red: 0.45, green: 0.25, blue: 0.45)
    static let plumDark = Color(red: 0.31, green: 0.16, blue: 0.31)
    static let ivory = Color(red: 0.98, green: 0.97, blue: 0.95)
}

struct MedFleetLogoMarkView: View {
    let progress: CGFloat

    var body: some View {
        ZStack {
            MedFleetLogoPiece(
                rotation: .degrees(0),
                innerPadding: 18,
                offset: pieceOffset(startX: -48, startY: 0, endX: -48, endY: 8, phaseStart: 0, phaseLength: 0.44),
                tilt: .degrees(-5 + (5 * pieceProgress(from: 0, length: 0.44)))
            )

            MedFleetLogoPiece(
                rotation: .degrees(90),
                innerPadding: 18,
                offset: pieceOffset(startX: 0, startY: 0, endX: 0, endY: -54, phaseStart: 0.12, phaseLength: 0.42),
                tilt: .degrees(5 - (5 * pieceProgress(from: 0.12, length: 0.42)))
            )

            MedFleetLogoPiece(
                rotation: .degrees(180),
                innerPadding: 18,
                offset: pieceOffset(startX: 0, startY: 0, endX: 50, endY: 12, phaseStart: 0.24, phaseLength: 0.42),
                tilt: .degrees(-4 + (4 * pieceProgress(from: 0.24, length: 0.42)))
            )

            MedFleetLogoPiece(
                rotation: .degrees(270),
                innerPadding: 18,
                offset: pieceOffset(startX: 0, startY: 0, endX: 2, endY: 72, phaseStart: 0.36, phaseLength: 0.42),
                tilt: .degrees(4 - (4 * pieceProgress(from: 0.36, length: 0.42)))
            )
        }
        .drawingGroup()
        .shadow(color: Color.black.opacity(0.06 + (0.05 * progress)), radius: 18, x: 0, y: 14)
    }

    private func pieceProgress(from start: CGFloat, length: CGFloat) -> CGFloat {
        guard length > 0 else { return 1 }
        let value = (progress - start) / length
        return min(max(value, 0), 1)
    }

    private func pieceOffset(startX: CGFloat, startY: CGFloat, endX: CGFloat, endY: CGFloat, phaseStart: CGFloat, phaseLength: CGFloat) -> CGSize {
        let local = pieceProgress(from: phaseStart, length: phaseLength)
        return CGSize(
            width: startX + ((endX - startX) * local),
            height: startY + ((endY - startY) * local)
        )
    }
}

struct MedFleetLogoPiece: View {
    let rotation: Angle
    let innerPadding: CGFloat
    let offset: CGSize
    let tilt: Angle

    var body: some View {
        CapsuleShape()
            .fill(
                LinearGradient(
                    colors: [MedFleetBrandPalette.plum, MedFleetBrandPalette.plumDark],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                CapsuleShape()
                    .inset(by: innerPadding)
                    .stroke(MedFleetBrandPalette.plumDark.opacity(0.8), lineWidth: 4)
            }
            .frame(width: 92, height: 112)
            .rotationEffect(rotation)
            .rotationEffect(tilt)
            .offset(offset)
    }
}

struct CapsuleShape: InsettableShape {
    var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.initiallyFilledCapsule(in: rect.insetBy(dx: insetAmount, dy: insetAmount))
        return path
    }

    func inset(by amount: CGFloat) -> some InsettableShape {
        var copy = self
        copy.insetAmount += amount
        return copy
    }
}

extension Path {
    mutating func initiallyFilledCapsule(in rect: CGRect) {
        let radius = rect.width / 2
        move(to: CGPoint(x: rect.minX, y: rect.maxY))
        addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        addArc(center: CGPoint(x: rect.minX + radius, y: rect.minY + radius),
               radius: radius,
               startAngle: .degrees(180),
               endAngle: .degrees(0),
               clockwise: false)
        addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        closeSubpath()
    }
}
