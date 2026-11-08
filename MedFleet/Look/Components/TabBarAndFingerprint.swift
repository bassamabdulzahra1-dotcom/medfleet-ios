import SwiftUI

struct TabItem {
    let icon: String
    let activeIcon: String
    let label: String
}

/// شريط تنقل سفلي عائم بأربعة تبويبات وزر مسح بارز في المنتصف.
struct MfTabBar: View {
    let items: [TabItem]
    @Binding var current: Int
    let onCenter: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            HStack(spacing: 0) {
                tab(0)
                tab(1)
                Color.clear.frame(maxWidth: .infinity)
                tab(2)
                tab(3)
            }
            .frame(height: 68)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: MF.ink.opacity(0.12), radius: 18, y: 12)
            .padding(.top, 18)

            Button(action: onCenter) {
                Image(systemName: "doc.text.viewfinder")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(MF.gold)
                    .frame(width: 58, height: 58)
                    .background(MF.pine, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: MF.pine.opacity(0.35), radius: 12, y: 10)
            }
            .buttonStyle(PressStyle())
            .accessibilityLabel("مسح فاتورة")
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
    }

    private func tab(_ i: Int) -> some View {
        let item = items[i]
        let selected = i == current
        return Button {
            current = i
        } label: {
            VStack(spacing: 4) {
                Image(systemName: selected ? item.activeIcon : item.icon)
                    .font(.system(size: 20, weight: selected ? .semibold : .regular))
                Text(item.label).font(MFFont.body(11, selected ? .bold : .medium))
            }
            .foregroundStyle(selected ? MF.pine : MF.ink3)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

enum FpState { case idle, busy, success, failure }

/// زر البصمة الدائري مع نبض ذهبي.
struct FingerprintButton: View {
    let state: FpState
    let label: String
    var size: CGFloat = 170
    let action: () -> Void

    private var fill: Color {
        switch state {
        case .success: return MF.success
        case .failure: return MF.danger
        case .idle, .busy: return MF.pine
        }
    }

    var body: some View {
        ZStack {
            if state == .idle {
                TimelineView(.animation) { ctx in
                    let t = ctx.date.timeIntervalSinceReferenceDate / 2.4
                    ZStack {
                        ForEach(0..<2, id: \.self) { i in
                            let k = (t + Double(i) * 0.5).truncatingRemainder(dividingBy: 1)
                            Circle()
                                .stroke(MF.gold, lineWidth: 1.5)
                                .frame(width: size, height: size)
                                .scaleEffect(1 + k * 0.45)
                                .opacity((1 - k) * 0.55)
                        }
                    }
                }
                .allowsHitTesting(false)
            }

            Button(action: action) {
                ZStack {
                    Circle().fill(fill)
                    Circle().strokeBorder(MF.gold.opacity(0.55), lineWidth: 1.5)
                    icon.transition(.scale(scale: 0.7).combined(with: .opacity))
                }
                .frame(width: size, height: size)
                .shadow(color: MF.pine.opacity(0.32), radius: 26, y: 20)
                .animation(.easeOut(duration: 0.25), value: state)
            }
            .buttonStyle(PressStyle())
            .disabled(state == .busy)
            .accessibilityLabel(label)
        }
        .frame(width: size * 1.5, height: size * 1.5)
    }

    @ViewBuilder private var icon: some View {
        switch state {
        case .busy:
            ProgressView().tint(MF.gold).scaleEffect(1.6)
        case .success:
            Image(systemName: "checkmark").font(.system(size: 64, weight: .semibold)).foregroundStyle(.white)
        case .failure:
            Image(systemName: "xmark").font(.system(size: 58, weight: .semibold)).foregroundStyle(.white)
        case .idle:
            Image(systemName: "touchid").font(.system(size: 84, weight: .light)).foregroundStyle(MF.gold)
        }
    }
}
