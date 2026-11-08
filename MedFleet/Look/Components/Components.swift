import SwiftUI

// MARK: - الأسطح

/// بطاقة بيضاء بظل ناعم.
struct MfCard<Content: View>: View {
    var radius: CGFloat = 22
    var padding = EdgeInsets(top: 18, leading: 18, bottom: 18, trailing: 18)
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) { content }
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .softShadow()
    }
}

/// دوائر ذهبية متحدة المركز — توقيع البراند.
struct Rings: View {
    var center = UnitPoint(x: -0.08, y: -0.3)
    var maxRadius: CGFloat = 150
    var count = 6

    var body: some View {
        Canvas { ctx, size in
            let c = CGPoint(x: size.width * center.x, y: size.height * center.y)
            let step = (maxRadius - 40) / CGFloat(max(count - 1, 1))
            for i in 0..<count {
                let r = 40 + step * CGFloat(i)
                ctx.stroke(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)),
                           with: .color(MF.ring), lineWidth: 1)
            }
        }
        .allowsHitTesting(false)
    }
}

/// البطاقة الصنوبرية الفاخرة.
struct PineCard<Content: View>: View {
    var padding: CGFloat = 22
    var radius: CGFloat = 28
    var ringsCenter = UnitPoint(x: -0.08, y: -0.3)
    var ringsRadius: CGFloat = 150
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) { content }
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                ZStack {
                    MF.pine
                    Rings(center: ringsCenter, maxRadius: ringsRadius)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .pineShadow()
    }
}

/// عمود قابل للتمرير بهوامش الشاشات.
struct ScreenScroll<Content: View>: View {
    var bottom: CGFloat = 130
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) { content }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, bottom)
        }
        .background(MF.porcelain.ignoresSafeArea())
    }
}

struct LoadingView: View {
    var body: some View {
        ProgressView().tint(MF.pine).frame(maxWidth: .infinity).padding(48)
    }
}

struct EmptyCard: View {
    let text: String
    var body: some View {
        MfCard { Text(text).font(MFFont.body()).foregroundStyle(MF.ink2) }
    }
}

// MARK: - الأزرار والترويسات

struct CircleIconButton: View {
    let systemName: String
    let label: String
    var size: CGFloat = 44
    var background: Color = .white
    var tint: Color = MF.ink
    var shadow = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: size, height: size)
                .background(background, in: Circle())
                .shadow(color: shadow ? MF.ink.opacity(0.08) : .clear, radius: 10, y: 6)
        }
        .buttonStyle(PressStyle())
        .accessibilityLabel(label)
    }
}

struct PageHeader: View {
    let title: String
    var subtitle: String? = nil
    var subtitleAbove = false
    var onBack: (() -> Void)? = nil
    var trailing: AnyView? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let onBack {
                HStack {
                    CircleIconButton(systemName: "chevron.backward", label: "رجوع", action: onBack)
                    Spacer()
                    trailing
                }
                .padding(.bottom, 14)
            }
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    if let subtitle, subtitleAbove { sub(subtitle) }
                    Text(title).font(MFFont.display(30)).foregroundStyle(MF.ink)
                    if let subtitle, !subtitleAbove { sub(subtitle) }
                }
                Spacer(minLength: 8)
                if onBack == nil { trailing }
            }
        }
    }

    private func sub(_ s: String) -> some View {
        Text(s).font(MFFont.body(13)).foregroundStyle(MF.ink2)
    }
}

struct SectionHeader: View {
    let title: String
    var action: String? = nil
    var onAction: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title).font(MFFont.body(13, .semibold)).foregroundStyle(MF.ink2)
            Spacer()
            if let action, let onAction {
                Button(action, action: onAction)
                    .font(MFFont.body(13, .semibold))
                    .foregroundStyle(MF.goldText)
                    .frame(minHeight: 36)
            }
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 6)
    }
}

struct PrimaryButton: View {
    let label: String
    var systemImage: String? = nil
    let action: (() -> Void)?

    var body: some View {
        let enabled = action != nil
        Button { action?() } label: {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage).foregroundStyle(enabled ? MF.gold : MF.ink3)
                }
                Text(label).font(MFFont.body(15, .bold))
            }
            .foregroundStyle(enabled ? Color.white : MF.ink3)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(enabled ? MF.pine : MF.sand, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: enabled ? MF.pine.opacity(0.28) : .clear, radius: 14, y: 10)
        }
        .buttonStyle(PressStyle())
        .disabled(!enabled)
    }
}

struct QuickAction: View {
    let systemImage: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(MF.pine)
                    .frame(width: 62, height: 62)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .softShadow(10)
                Text(label).font(MFFont.body(12, .medium)).foregroundStyle(MF.ink)
            }
        }
        .buttonStyle(PressStyle())
    }
}

// MARK: - القوائم

/// قائمة مجمّعة داخل بطاقة واحدة بفواصل رفيعة.
struct GroupedList<Item, Row: View>: View {
    let items: [Item]
    let row: (Item) -> Row

    init(_ items: [Item], @ViewBuilder row: @escaping (Item) -> Row) {
        self.items = items
        self.row = row
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                if index > 0 { Rectangle().fill(MF.line).frame(height: 1) }
                row(item)
            }
        }
        .padding(.horizontal, 16)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .softShadow()
    }
}

struct ListRow: View {
    let title: String
    var subtitle: String? = nil
    var titleColor: Color = MF.ink
    var minHeight: CGFloat = 64
    var leading: AnyView? = nil
    var trailing: AnyView? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        if let action {
            Button(action: action) { content }.buttonStyle(.plain)
        } else {
            content
        }
    }

    private var content: some View {
        HStack(spacing: 12) {
            leading
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(MFFont.body(14.5, .semibold)).foregroundStyle(titleColor).lineLimit(1)
                if let subtitle {
                    Text(subtitle).font(MFFont.body(12)).foregroundStyle(MF.ink2).lineLimit(1)
                }
            }
            Spacer(minLength: 8)
            trailing
        }
        .padding(.vertical, 10)
        .frame(minHeight: minHeight)
        .contentShape(Rectangle())
    }
}

struct IconTile: View {
    var systemImage: String? = nil
    var text: String? = nil
    var bg: Color = MF.mintTint
    var fg: Color = MF.pine
    var size: CGFloat = 44
    var radius: CGFloat = 14

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: radius, style: .continuous).fill(bg)
            if let systemImage {
                Image(systemName: systemImage).font(.system(size: size * 0.42)).foregroundStyle(fg)
            } else {
                Text(text ?? "").font(MFFont.display(size * 0.38)).foregroundStyle(fg)
            }
        }
        .frame(width: size, height: size)
    }
}

struct StatusPill: View {
    let label: String
    var bg: Color = MF.mintTint
    var fg: Color = MF.pine

    var body: some View {
        Text(label)
            .font(MFFont.body(11.5, .bold))
            .foregroundStyle(fg)
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .background(bg, in: Capsule())
    }
}

// MARK: - الأرقام

struct MoneyText: View {
    let value: Int?
    var size: CGFloat = 15
    var weight: Font.Weight = .medium
    var color: Color = MF.ink
    var currency = false
    var currencyColor: Color = MF.goldText

    var body: some View {
        let number = Text(moneyOrDash(value)).font(MFFont.display(size, weight)).foregroundColor(color)
        if currency && value != nil {
            number + Text("  د.ع").font(MFFont.body(max(12, size * 0.36))).foregroundColor(currencyColor)
        } else {
            number
        }
    }
}

/// شريط مقسوم بنسبتين (POS / خارج).
struct SplitBar: View {
    let fraction: Double
    let first: Color
    let second: Color
    var height: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            let f = min(max(fraction, 0), 1)
            let w = geo.size.width - 3
            HStack(spacing: 3) {
                Capsule().fill(first).frame(width: w * f)
                Capsule().fill(second).frame(width: w * (1 - f))
            }
        }
        .frame(height: height)
    }
}

struct LegendDot: View {
    let color: Color
    let label: String
    var textColor: Color = MF.ink2

    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(MFFont.body(12)).foregroundStyle(textColor)
        }
    }
}

// MARK: - المدخلات

/// مفتاح مجزأ (حضور/انصراف، اليوم/الأسبوع/الشهر).
struct Segmented<Key: Hashable>: View {
    let options: [(Key, String)]
    @Binding var value: Key

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options.indices, id: \.self) { i in
                let (key, label) = options[i]
                let selected = key == value
                Button {
                    withAnimation(.easeOut(duration: 0.2)) { value = key }
                } label: {
                    Text(label)
                        .font(MFFont.body(14, .bold))
                        .foregroundStyle(selected ? MF.ink : MF.ink2)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background {
                            if selected {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.white)
                                    .shadow(color: MF.ink.opacity(0.12), radius: 2, y: 1)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(4)
        .frame(height: 48)
        .background(MF.sand, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct FilterChips<Key: Hashable>: View {
    let options: [(Key, String)]
    @Binding var value: Key

    var body: some View {
        HStack(spacing: 8) {
            ForEach(options.indices, id: \.self) { i in
                let (key, label) = options[i]
                let selected = key == value
                Button { value = key } label: {
                    Text(label)
                        .font(MFFont.body(13, .semibold))
                        .foregroundStyle(selected ? Color.white : MF.ink)
                        .padding(.horizontal, 16)
                        .frame(height: 38)
                        .background(selected ? MF.pine : Color.white, in: Capsule())
                        .overlay(Capsule().stroke(selected ? MF.pine : MF.ink.opacity(0.1), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
    }
}

struct SearchField: View {
    let hint: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundStyle(MF.ink2)
            TextField("", text: $text, prompt: Text(hint).foregroundColor(MF.ink3))
                .font(MFFont.body(14.5))
                .foregroundStyle(MF.ink)
                .submitLabel(.search)
        }
        .padding(.horizontal, 14)
        .frame(height: 52)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .softShadow(8)
    }
}

// MARK: - الوقت

/// يعيد بناء المحتوى كل ثانية بالوقت الحالي.
struct LiveClock<Content: View>: View {
    @ViewBuilder var content: (Date) -> Content

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { ctx in
            content(ctx.date)
        }
    }
}
