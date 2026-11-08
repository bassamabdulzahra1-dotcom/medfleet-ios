import SwiftUI

// MARK: - الماسحة

/// شاشة الكاميرا. ضع AVCaptureVideoPreviewLayer (أو DataScannerViewController للنصوص والباركود)
/// مكان منطقة المعاينة عند الربط.
struct ScannerView: View {
    let mode: ScanMode
    @Environment(Router.self) private var router
    @State private var flash = false

    private var invoice: Bool { mode == .invoice }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                CircleIconButton(systemName: "xmark", label: "إغلاق", background: .white.opacity(0.1), tint: .white, shadow: false) {
                    router.pop()
                }
                Spacer()
                Text(invoice ? "فاتورة شراء" : "مسح باركود").font(MFFont.display(16, .medium)).foregroundStyle(.white)
                Spacer()
                CircleIconButton(
                    systemName: flash ? "bolt.fill" : "bolt.slash.fill",
                    label: "الفلاش",
                    background: flash ? MF.gold : .white.opacity(0.1),
                    tint: flash ? MF.pine : .white,
                    shadow: false
                ) { flash.toggle() }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            Viewfinder(aspect: invoice ? 0.68 : 1.3)
                .padding(.horizontal, 34)
                .padding(.top, 30)
                .frame(maxHeight: .infinity, alignment: .top)

            HStack(spacing: 8) {
                Image(systemName: "info.circle").foregroundStyle(MF.gold)
                Text(invoice ? "اجعل جدول الأصناف كاملاً داخل الإطار" : "وجّه الكاميرا نحو الباركود")
                    .font(MFFont.body(13)).foregroundStyle(Color(hex: 0xDCE7E3))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.white.opacity(0.08), in: Capsule())
            .padding(.top, 20)

            HStack {
                sideButton("photo.on.rectangle", "المعرض")
                Spacer()
                Button { /* TODO: التقاط الصورة واستخراج الأصناف */ } label: {
                    Circle().fill(.white)
                        .padding(6)
                        .frame(width: 82, height: 82)
                        .overlay(Circle().stroke(MF.gold, lineWidth: 3))
                }
                .buttonStyle(PressStyle())
                .accessibilityLabel("التقاط")
                Spacer()
                sideButton("square.and.pencil", "إدخال يدوي")
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 28)
        }
        .background(MF.pineDeep.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    private func sideButton(_ icon: String, _ label: String) -> some View {
        Button {} label: {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(PressStyle())
        .accessibilityLabel(label)
    }
}

private struct Viewfinder: View {
    let aspect: CGFloat

    var body: some View {
        TimelineView(.animation) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate / 1.6
            let phase = t.truncatingRemainder(dividingBy: 2)
            let k = phase < 1 ? phase : 2 - phase
            let eased = k * k * (3 - 2 * k)
            Canvas { g, size in
                let w = size.width, h = size.height, len: CGFloat = 46
                let inner = CGRect(x: 18, y: 18, width: w - 36, height: h - 36)
                g.fill(Path(roundedRect: inner, cornerRadius: 10), with: .color(MF.porcelain.opacity(0.08)))

                func corner(_ a: CGPoint, _ c: CGPoint, _ b: CGPoint) {
                    var p = Path()
                    p.move(to: a)
                    p.addQuadCurve(to: b, control: c)
                    g.stroke(p, with: .color(MF.gold), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                }
                corner(CGPoint(x: 0, y: len), .zero, CGPoint(x: len, y: 0))
                corner(CGPoint(x: w - len, y: 0), CGPoint(x: w, y: 0), CGPoint(x: w, y: len))
                corner(CGPoint(x: 0, y: h - len), CGPoint(x: 0, y: h), CGPoint(x: len, y: h))
                corner(CGPoint(x: w - len, y: h), CGPoint(x: w, y: h), CGPoint(x: w, y: h - len))

                let y = 18 + (h - 38) * eased
                var line = Path()
                line.move(to: CGPoint(x: 18, y: y))
                line.addLine(to: CGPoint(x: w - 18, y: y))
                g.stroke(line, with: .color(MF.gold.opacity(0.35)), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                g.stroke(line, with: .color(MF.gold), style: StrokeStyle(lineWidth: 2, lineCap: .round))
            }
        }
        .aspectRatio(aspect, contentMode: .fit)
    }
}

// MARK: - الجرد

struct StocktakeView: View {
    @Environment(Router.self) private var router
    @State private var query = ""
    @State private var note = ""
    // TODO: اربط الأصناف الممسوحة والفرق المالي بالـ API
    private let itemCount = 0
    private let variance = 0

    var body: some View {
        VStack(spacing: 0) {
            ScreenScroll(bottom: 20) {
                PageHeader(title: "الجرد المخزني", subtitle: "باركود سريع، إدخال يدوي، وفرق مالي تلقائي", onBack: { router.pop() })
                Button { router.push(.scanner(.barcode)) } label: {
                    PineCard(ringsCenter: UnitPoint(x: -0.08, y: 0.2), ringsRadius: 110) {
                        HStack(spacing: 16) {
                            IconTile(systemImage: "barcode.viewfinder", bg: MF.gold.opacity(0.16), fg: MF.gold, size: 64, radius: 20)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("ابدأ المسح").font(MFFont.display(19, .medium)).foregroundStyle(.white)
                                Text("وجّه الكاميرا نحو باركود المنتج").font(MFFont.body(13)).foregroundStyle(MF.onPineMuted)
                            }
                        }
                    }
                }
                .buttonStyle(PressStyle())
                .padding(.top, 20)

                SearchField(hint: "أو اكتب اسم المنتج", text: $query).padding(.top, 12)

                MfCard(radius: 24) {
                    HStack {
                        metric("أصناف مسجلة", "\(itemCount)", currency: false)
                        Rectangle().fill(MF.line).frame(width: 1, height: 44).padding(.trailing, 18)
                        metric("الفرق المالي", "\(variance)", currency: true)
                    }
                    TextField("", text: $note, prompt: Text("ملاحظة القيد المحاسبي (اختياري)").foregroundColor(MF.ink3), axis: .vertical)
                        .lineLimit(2...4)
                        .font(MFFont.body(14))
                        .padding(14)
                        .background(MF.porcelain, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .padding(.top, 14)
                }
                .padding(.top, 12)

                Text("الأصناف الممسوحة ستظهر هنا")
                    .font(MFFont.body(13)).foregroundStyle(MF.ink2)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
            }
            PrimaryButton(label: "ترحيل الفرق للحسابات", action: itemCount > 0 ? {} : nil)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
        }
        .background(MF.porcelain.ignoresSafeArea())
    }

    private func metric(_ label: String, _ value: String, currency: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label).font(MFFont.body(12)).foregroundStyle(MF.ink2)
            if currency {
                Text(value).font(MFFont.display(26, .light)).foregroundColor(MF.ink)
                    + Text("  د.ع").font(MFFont.body(12)).foregroundColor(MF.goldText)
            } else {
                Text(value).font(MFFont.display(26, .light)).foregroundStyle(MF.ink)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - مردود الشراء

struct ReturnsView: View {
    @Environment(AppStore.self) private var store
    @Environment(Router.self) private var router
    @State private var items: [LookReturn]?

    var body: some View {
        VStack(spacing: 0) {
            ScreenScroll(bottom: 20) {
                PageHeader(title: "مردود الشراء", subtitle: "الأصناف المُرجعة للمورّدين", onBack: { router.pop() })
                if let list = items {
                    MfCard(radius: 24) {
                        HStack {
                            VStack(alignment: .leading, spacing: 0) {
                                Text("إجمالي المردودات").font(MFFont.body(12)).foregroundStyle(MF.ink2)
                                MoneyText(value: list.reduce(0) { $0 + $1.amount }, size: 28, weight: .light, currency: true)
                            }
                            Spacer()
                            StatusPill(label: "\(list.count) مستند", bg: MF.goldTint, fg: MF.goldText)
                        }
                    }
                    .padding(.top, 20)

                    SectionHeader(title: "المستندات").padding(.top, 22)
                    if list.isEmpty {
                        EmptyCard(text: "لا توجد مردودات")
                    } else {
                        GroupedList(list) { r in
                            ListRow(
                                title: r.vendor,
                                subtitle: "\(r.ref) · فاتورة \(r.invoiceNo)",
                                minHeight: 74,
                                leading: AnyView(IconTile(systemImage: "arrow.uturn.backward", bg: MF.goldTint, fg: MF.goldText, size: 46, radius: 15)),
                                trailing: AnyView(MoneyText(value: r.amount)),
                                action: {}
                            )
                        }
                    }
                } else {
                    LoadingView()
                }
            }
            PrimaryButton(label: "مردود جديد", systemImage: "plus", action: { router.push(.returnNew) })
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
        }
        .background(MF.porcelain.ignoresSafeArea())
        .task { items = await store.repo.purchaseReturns() }
    }
}
