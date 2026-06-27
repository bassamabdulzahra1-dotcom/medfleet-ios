import SwiftUI

struct BuyerInventoryAuditView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var query = ""
    @State private var note = ""
    @State private var results: [InventoryItem] = []
    @State private var lines: [AuditLine] = []

    @State private var loadingResults = false
    @State private var saving = false
    @State private var error: String?
    @State private var success: String?

    @State private var showScanner = false
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 0) {
            header

            controls

            if !results.isEmpty {
                resultList
            }

            totalsCard

            lineTable

            Spacer(minLength: 8)

            saveButton
        }
        .background(LinearGradient(colors: [MFColors.bgTop, MFColors.bgBottom], startPoint: .top, endPoint: .bottom).ignoresSafeArea())
        .environment(\.layoutDirection, .rightToLeft)
        .sheet(isPresented: $showScanner) {
            BarcodeScannerSheet { code in
                showScanner = false
                Task { await addFromBarcode(code) }
            } onError: { msg in
                showScanner = false
                error = msg
            }
            .ignoresSafeArea()
        }
        .onChange(of: query) { value in
            success = nil
            if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                results = []
                return
            }
            searchTask?.cancel()
            searchTask = Task {
                try? await Task.sleep(nanoseconds: 300_000_000)
                if Task.isCancelled { return }
                await searchByNameOrBarcode(value)
            }
        }
    }

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
            VStack(alignment: .trailing, spacing: 2) {
                Text("الجرد المخزني")
                    .font(.headline)
                    .foregroundStyle(MFColors.navy)
                Text("باركود سريع + إدخال يدوي + فرق مالي")
                    .font(.caption2)
                    .foregroundStyle(MFColors.muted)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
    }

    private var controls: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Button {
                    if BarcodeScannerAvailability.isAvailable {
                        error = nil
                        showScanner = true
                    } else {
                        error = "جهازك لا يدعم المسح المباشر. استخدم البحث بالاسم أو الباركود."
                    }
                } label: {
                    Label("مسح باركود", systemImage: "barcode.viewfinder")
                        .font(.subheadline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(LinearGradient(colors: [MFColors.navy2, MFColors.navy], startPoint: .top, endPoint: .bottom))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 11))
                }

                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").foregroundStyle(MFColors.muted)
                    TextField("اكتب اسم المنتج أو الباركود", text: $query)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 11))
                .overlay(RoundedRectangle(cornerRadius: 11).stroke(MFColors.muted.opacity(0.25), lineWidth: 1))
            }

            if let error {
                messageBanner(error, tint: MFColors.danger)
            }
            if let success {
                messageBanner(success, tint: MFColors.ok)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }

    @ViewBuilder
    private var resultList: some View {
        VStack(alignment: .trailing, spacing: 8) {
            Text(loadingResults ? "جاري البحث..." : "نتائج البحث")
                .font(.caption)
                .foregroundStyle(MFColors.muted)
                .frame(maxWidth: .infinity, alignment: .trailing)

            ForEach(results) { item in
                Button {
                    addLine(item)
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(MFColors.ok)
                            .font(.title3)
                        Spacer()
                        VStack(alignment: .trailing, spacing: 3) {
                            Text(item.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(MFColors.navy)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                            Text("رصيد المخزن: \(MFFormat.money(item.qtyOnHand ?? 0))")
                                .font(.caption2)
                                .foregroundStyle(MFColors.muted)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }
                    .padding(10)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var totalsCard: some View {
        VStack(alignment: .trailing, spacing: 8) {
            Text("ملخص الفروقات")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MFColors.navy)

            HStack {
                Text("\(lines.count)")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(MFColors.navy)
                    .clipShape(Capsule())
                Text("أصناف مسجلة")
                    .font(.caption)
                    .foregroundStyle(MFColors.muted)
                Spacer()
                Text("القيمة المالية: \(MFFormat.money(totalDiffValue)) د.ع")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(totalDiffValue >= 0 ? MFColors.ok : MFColors.danger)
            }

            TextField("ملاحظة القيد المحاسبي (اختياري)", text: $note)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(MFColors.muted.opacity(0.22), lineWidth: 1))
        }
        .padding(14)
        .background(Color.white.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }

    @ViewBuilder
    private var lineTable: some View {
        if lines.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "shippingbox")
                    .font(.title)
                    .foregroundStyle(MFColors.muted)
                Text("ابدأ بالمسح أو البحث لإضافة الأصناف")
                    .font(.caption)
                    .foregroundStyle(MFColors.muted)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 18)
        } else {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach($lines) { $line in
                        auditRow(line: $line)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 20)
            }
        }
    }

    private var saveButton: some View {
        Button {
            Task { await submitAudit() }
        } label: {
            HStack {
                if saving { ProgressView().tint(.white) }
                Text(saving ? "جاري ترحيل الفرق..." : "ترحيل الفرق للحسابات")
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(LinearGradient(colors: [MFColors.gold, MFColors.goldDark], startPoint: .top, endPoint: .bottom))
            .foregroundStyle(MFColors.navy)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .disabled(lines.isEmpty || saving)
        .opacity((lines.isEmpty || saving) ? 0.55 : 1)
    }

    @ViewBuilder
    private func auditRow(line: Binding<AuditLine>) -> some View {
        let item = line.wrappedValue.item
        let stock = line.wrappedValue.stockQty
        let diff = line.wrappedValue.diffQty
        let diffValue = line.wrappedValue.diffValue

        VStack(alignment: .trailing, spacing: 8) {
            HStack {
                Button {
                    removeLine(line.wrappedValue.id)
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(MFColors.danger)
                        .padding(8)
                        .background(MFColors.danger.opacity(0.1))
                        .clipShape(Circle())
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text(item.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(MFColors.navy)
                    if let bc = item.barcode, !bc.isEmpty {
                        Text("باركود: \(bc)")
                            .font(.caption2)
                            .foregroundStyle(MFColors.muted)
                    }
                }
            }

            HStack(spacing: 10) {
                metricBox(title: "المخزن", value: MFFormat.money(stock), tint: MFColors.navy)

                VStack(alignment: .trailing, spacing: 3) {
                    Text("الحالية")
                        .font(.caption2)
                        .foregroundStyle(MFColors.muted)
                    TextField("0", text: line.currentQtyText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 6)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(MFColors.muted.opacity(0.2), lineWidth: 1))
                }
                .frame(maxWidth: .infinity)

                metricBox(title: "الفرق", value: MFFormat.money(diff), tint: diff >= 0 ? MFColors.ok : MFColors.danger)
            }

            HStack {
                Text("\(MFFormat.money(abs(diffValue))) د.ع")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(diffValue >= 0 ? MFColors.ok : MFColors.danger)
                Text(diffValue >= 0 ? "قيد زيادة" : "قيد نقصان")
                    .font(.caption2)
                    .foregroundStyle(MFColors.muted)
                Spacer()
                Text("قيمة الفرق")
                    .font(.caption2)
                    .foregroundStyle(MFColors.muted)
            }
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 3, y: 1)
    }

    private func metricBox(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .center, spacing: 3) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(MFColors.muted)
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(tint.opacity(0.09))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func messageBanner(_ message: String, tint: Color) -> some View {
        Text(message)
            .font(.caption)
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(tint.opacity(0.11))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var totalDiffValue: Double {
        lines.reduce(0) { $0 + $1.diffValue }
    }

    private func searchByNameOrBarcode(_ text: String) async {
        guard let api = appState.api else { return }
        loadingResults = true
        do {
            results = try await api.buyerInventory(q: text)
        } catch {
            results = []
            self.error = mapError(error, fallback: "تعذر البحث عن المنتج")
        }
        loadingResults = false
    }

    private func addFromBarcode(_ code: String) async {
        guard let api = appState.api else { return }
        error = nil
        success = nil
        do {
            if let item = try await api.buyerInventoryByBarcode(code) {
                addLine(item)
                success = "تمت إضافة المنتج من الباركود"
            } else {
                error = "لم يتم العثور على منتج بهذا الباركود"
                query = code
                await searchByNameOrBarcode(code)
            }
        } catch {
            self.error = mapError(error, fallback: "فشل قراءة الباركود من المخزن")
        }
    }

    private func mapError(_ error: Error, fallback: String) -> String {
        if let apiError = error as? APIError {
            switch apiError {
            case .unauthorized:
                return "انتهت الجلسة. سجل دخول مرة ثانية"
            case .http(let code, let msg):
                if code == 404 { return "خدمة المخزن غير مفعلة على السيرفر" }
                if code >= 500 { return "السيرفر غير متاح حالياً. حاول بعد قليل" }
                return msg ?? fallback
            default:
                return apiError.localizedDescription
            }
        }
        return fallback
    }

    private func addLine(_ item: InventoryItem) {
        if lines.contains(where: { $0.item.id == item.id }) {
            success = "المنتج مضاف مسبقاً"
            return
        }
        lines.insert(AuditLine(item: item), at: 0)
        results.removeAll(where: { $0.id == item.id })
        query = ""
    }

    private func removeLine(_ id: UUID) {
        lines.removeAll(where: { $0.id == id })
    }

    private func submitAudit() async {
        guard let api = appState.api else { return }
        error = nil
        success = nil
        saving = true
        defer { saving = false }

        let payload: [BuyerInventoryAuditLineInput] = lines.map {
            BuyerInventoryAuditLineInput(
                productId: $0.item.id,
                productName: $0.item.name,
                barcode: $0.item.barcode,
                stockQty: $0.stockQty,
                currentQty: $0.currentQty,
                diffQty: $0.diffQty,
                unitCost: $0.unitCost,
                diffValue: $0.diffValue
            )
        }

        do {
            let r = try await api.buyerInventoryAuditCommit(lines: payload, note: note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : note)
            let ref = r.reference?.isEmpty == false ? " - مرجع: \(r.reference!)" : ""
            success = (r.message?.isEmpty == false ? r.message! : "تم ترحيل الفروقات للحسابات بنجاح") + ref
            note = ""
        } catch {
            self.error = "تعذر ترحيل الفروقات. تأكد من توفر API الجرد في السيرفر."
        }
    }
}

private struct AuditLine: Identifiable {
    let id = UUID()
    let item: InventoryItem
    var currentQtyText: String

    init(item: InventoryItem) {
        self.item = item
        self.currentQtyText = MFFormat.money(item.qtyOnHand ?? 0)
    }

    var stockQty: Double { item.qtyOnHand ?? 0 }

    var currentQty: Double {
        MFFormat.westernDouble(currentQtyText) ?? 0
    }

    var diffQty: Double {
        currentQty - stockQty
    }

    var unitCost: Double {
        item.standardCost ?? item.salePrice ?? 0
    }

    var diffValue: Double {
        diffQty * unitCost
    }
}
