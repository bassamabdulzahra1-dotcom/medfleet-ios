import SwiftUI

struct BuyerScanView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var pickedImageData: Data?
    @State private var pickedThumbnail: UIImage?
    @State private var preview: BuyerPreviewData?
    @State private var result: BuyerScanData?

    @State private var loadingPreview = false
    @State private var committing = false
    @State private var error: String?

    @State private var recent: [BuyerScanOrder] = []
    @State private var loadingRecent = true

    @State private var showCamera = false
    @State private var showLibrary = false

    var body: some View {
        ScrollView {
            VStack(alignment: .trailing, spacing: 14) {
                header

                if result == nil {
                    pickerCard
                }

                if let error {
                    errorBanner(error)
                }

                if let preview, result == nil {
                    reviewCard(preview)
                }

                if let result {
                    resultCard(result)
                }

                recentSection
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
        }
        .background(LinearGradient(colors: [MFColors.bgTop, MFColors.bgBottom], startPoint: .top, endPoint: .bottom).ignoresSafeArea())
        .environment(\.layoutDirection, .rightToLeft)
        .task { await loadRecent() }
        .fullScreenCover(isPresented: $showCamera) {
            ImagePicker(source: .camera) { data in handlePicked(data) }
                .ignoresSafeArea()
        }
        .sheet(isPresented: $showLibrary) {
            ImagePicker(source: .library) { data in handlePicked(data) }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(MFColors.navy)
                    .frame(width: 40, height: 40)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.06), radius: 3, y: 1)
            }
            Spacer()
            Text("ماسحة الفاتورة")
                .font(.headline)
                .foregroundStyle(MFColors.navy)
        }
        .padding(.top, 6)
    }

    // MARK: - Picker card

    private var pickerCard: some View {
        VStack(alignment: .trailing, spacing: 12) {
            if let thumb = pickedThumbnail {
                Image(uiImage: thumb)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(MFColors.cream)
                    .frame(height: 130)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "doc.text.viewfinder")
                                .font(.largeTitle)
                                .foregroundStyle(MFColors.gold)
                            Text("صوّر فاتورة الشراء أو اخترها من المعرض")
                                .font(.caption)
                                .foregroundStyle(MFColors.muted)
                        }
                    )
            }

            HStack(spacing: 10) {
                actionButton(title: "تصوير", icon: "camera.fill", filled: true) {
                    error = nil
                    showCamera = true
                }
                actionButton(title: "من المعرض", icon: "photo.on.rectangle", filled: false) {
                    error = nil
                    showLibrary = true
                }
            }

            if pickedImageData != nil {
                Button {
                    Task { await runPreview() }
                } label: {
                    HStack {
                        if loadingPreview { ProgressView().tint(MFColors.navy) }
                        Text(loadingPreview ? "جاري القراءة…" : "قراءة الفاتورة")
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(LinearGradient(colors: [MFColors.gold, MFColors.goldDark], startPoint: .top, endPoint: .bottom))
                    .foregroundStyle(MFColors.navy)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(loadingPreview)
                .opacity(loadingPreview ? 0.6 : 1)
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    // MARK: - Review card (before commit)

    private func reviewCard(_ p: BuyerPreviewData) -> some View {
        VStack(alignment: .trailing, spacing: 10) {
            Text("مراجعة الأصناف المستخرجة")
                .font(.subheadline.bold())
                .foregroundStyle(MFColors.navy)

            metaRow(label: "المورّد", value: p.supplierName ?? "غير معروف")
            if let v = p.vendorRef, !v.isEmpty { metaRow(label: "رقم الفاتورة", value: v) }
            metaRow(label: "الإجمالي", value: "\(MFFormat.money(Double(p.amountTotal ?? "0") ?? 0)) د.ع")

            Divider()

            ForEach(Array(p.lines.enumerated()), id: \.offset) { _, line in
                lineRow(line)
            }

            Button {
                Task { await runCommit(p) }
            } label: {
                HStack {
                    if committing { ProgressView().tint(.white) }
                    Text(committing ? "جاري الحفظ…" : "اعتماد كمسوّدة شراء")
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(MFColors.navy)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(committing)
            .opacity(committing ? 0.6 : 1)
            .padding(.top, 4)
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    // MARK: - Result card (after commit)

    private func resultCard(_ r: BuyerScanData) -> some View {
        VStack(alignment: .trailing, spacing: 10) {
            HStack {
                Spacer()
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(MFColors.ok)
                Text("تم إنشاء المسوّدة")
                    .font(.subheadline.bold())
                    .foregroundStyle(MFColors.navy)
            }

            if let ref = r.order.ref { metaRow(label: "الرقم المرجعي", value: ref) }
            metaRow(label: "المورّد", value: r.order.supplierName ?? "غير معروف")
            metaRow(label: "الإجمالي", value: "\(MFFormat.money(Double(r.order.amountTotal ?? "0") ?? 0)) د.ع")
            metaRow(label: "عدد الأصناف", value: "\(r.lines.count)")

            Button {
                resetForNewScan()
            } label: {
                Text("مسح فاتورة جديدة")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(LinearGradient(colors: [MFColors.gold, MFColors.goldDark], startPoint: .top, endPoint: .bottom))
                    .foregroundStyle(MFColors.navy)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    // MARK: - Recent scans

    private var recentSection: some View {
        VStack(alignment: .trailing, spacing: 10) {
            Text("آخر المسوّدات")
                .font(.subheadline.bold())
                .foregroundStyle(MFColors.navy)
                .frame(maxWidth: .infinity, alignment: .trailing)

            if loadingRecent {
                ProgressView().tint(MFColors.navy).frame(maxWidth: .infinity)
            } else if recent.isEmpty {
                Text("لا توجد مسوّدات بعد")
                    .font(.caption)
                    .foregroundStyle(MFColors.muted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            } else {
                ForEach(recent) { o in
                    recentRow(o)
                }
            }
        }
        .padding(.top, 4)
    }

    private func recentRow(_ o: BuyerScanOrder) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(MFFormat.money(Double(o.amountTotal ?? "0") ?? 0)) د.ع")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(MFColors.goldDark)
                if let n = o.lineCount {
                    Text("\(n) صنف").font(.caption2).foregroundStyle(MFColors.muted)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(o.ref ?? "—").font(.subheadline.weight(.semibold)).foregroundStyle(MFColors.navy)
                Text(o.supplierName ?? "بدون مورّد").font(.caption).foregroundStyle(MFColors.muted)
            }
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 3, y: 1)
    }

    // MARK: - Pieces

    private func lineRow(_ line: BuyerScanLine) -> some View {
        VStack(alignment: .trailing, spacing: 4) {
            HStack(alignment: .top) {
                badge(for: line)
                Spacer()
                Text(line.productName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MFColors.navy)
                    .multilineTextAlignment(.trailing)
            }
            HStack(spacing: 10) {
                Spacer()
                Text("الكمية: \(fmt(line.qty))").font(.caption).foregroundStyle(MFColors.muted)
                Text("السعر: \(fmt(line.unitPrice))").font(.caption).foregroundStyle(MFColors.muted)
            }
            if let b = line.batchNumber, !b.isEmpty {
                Text("الدفعة: \(b)\(line.expiryDate.map { " • انتهاء: \($0)" } ?? "")")
                    .font(.caption2).foregroundStyle(MFColors.muted)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(.vertical, 6)
        .overlay(Divider(), alignment: .bottom)
    }

    private func badge(for line: BuyerScanLine) -> some View {
        Group {
            if line.matched {
                Text("موجود بالمخزن • الرصيد: \(fmt(line.inStock))")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(MFColors.ok)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(MFColors.ok.opacity(0.12))
                    .clipShape(Capsule())
            } else {
                Text("منتج جديد — يحتاج تسعير")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(MFColors.goldDark)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(MFColors.gold.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
    }

    private func metaRow(label: String, value: String) -> some View {
        HStack {
            Text(value).font(.subheadline.weight(.medium)).foregroundStyle(MFColors.navy)
            Spacer()
            Text(label).font(.caption).foregroundStyle(MFColors.muted)
        }
    }

    private func errorBanner(_ msg: String) -> some View {
        Text(msg)
            .font(.caption)
            .foregroundStyle(MFColors.danger)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(12)
            .background(MFColors.danger.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    @ViewBuilder
    private func actionButton(title: String, icon: String, filled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title).fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(filled ? MFColors.navy : Color.white)
            .foregroundStyle(filled ? .white : MFColors.navy)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(MFColors.navy.opacity(filled ? 0 : 0.25), lineWidth: 1)
            )
        }
    }

    // MARK: - Actions

    private func handlePicked(_ data: Data) {
        pickedImageData = data
        pickedThumbnail = UIImage(data: data)
        preview = nil
        result = nil
        error = nil
    }

    private func runPreview() async {
        guard let api = appState.api, let data = pickedImageData else { return }
        loadingPreview = true
        error = nil
        defer { loadingPreview = false }
        do {
            preview = try await api.buyerScanPreview(imageData: data)
        } catch {
            self.error = friendly(error)
        }
    }

    private func runCommit(_ p: BuyerPreviewData) async {
        guard let api = appState.api else { return }
        committing = true
        error = nil
        defer { committing = false }
        do {
            result = try await api.buyerScanCommit(imageUrl: p.imageUrl, extracted: p.extracted)
            preview = nil
            await loadRecent()
        } catch {
            self.error = friendly(error)
        }
    }

    private func loadRecent() async {
        guard let api = appState.api else { return }
        loadingRecent = true
        defer { loadingRecent = false }
        recent = (try? await api.buyerScans()) ?? recent
    }

    private func resetForNewScan() {
        pickedImageData = nil
        pickedThumbnail = nil
        preview = nil
        result = nil
        error = nil
    }

    private func fmt(_ s: String?) -> String {
        guard let s, let d = Double(s) else { return s ?? "0" }
        return MFFormat.money(d)
    }

    private func friendly(_ error: Error) -> String {
        if let api = error as? APIError {
            switch api {
            case .http(_, let msg): return msg ?? "حدث خطأ غير متوقع."
            case .unauthorized: return "انتهت الجلسة، سجّل الدخول مجدداً."
            case .decoding: return "تعذّر قراءة رد الخادم."
            case .invalidURL: return "تعذّر الاتصال بالخادم."
            }
        }
        return "تعذّر الاتصال بالخادم."
    }
}
