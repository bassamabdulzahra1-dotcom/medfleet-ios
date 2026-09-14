import SwiftUI

private struct DraftReturnLine: Identifiable {
    let id = UUID()
    let name: String
    let barcode: String?
    let qty: Double
    let unitPrice: Double
    var subtotal: Double { qty * unitPrice }
}

struct BuyerPurchaseReturnEditorView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    let onSaved: () -> Void

    @State private var vendor = ""
    @State private var invoiceNo = ""
    @State private var offices: [BuyerSupplierOffice] = []
    @FocusState private var vendorFocused: Bool
    @State private var lines: [DraftReturnLine] = []
    @State private var saving = false
    @State private var error: String?

    @State private var showScanner = false
    @State private var showManual = false
    @State private var showQty = false
    @State private var pendingName = ""
    @State private var pendingBarcode: String?
    @State private var pendingPrice: Double = 0
    @State private var qtyText = "1"

    private var total: Double { lines.reduce(0) { $0 + $1.subtotal } }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .trailing, spacing: 12) {
                vendorSearchField
                    field("رقم الفاتورة", text: $invoiceNo)

                    HStack(spacing: 8) {
                        Button {
                            if BarcodeScannerAvailability.isAvailable {
                                error = nil
                                showScanner = true
                            } else {
                                error = "جهازك لا يدعم المسح المباشر. اكتب اسم المنتج."
                            }
                        } label: {
                            Label("باركود", systemImage: "barcode.viewfinder")
                                .font(.subheadline.weight(.bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 11)
                                .background(LinearGradient(colors: [MFColors.button, MFColors.buttonDark], startPoint: .top, endPoint: .bottom))
                                .foregroundStyle(MFColors.gold)
                                .overlay(RoundedRectangle(cornerRadius: 11).stroke(MFColors.gold.opacity(0.14), lineWidth: 1))
                                .clipShape(RoundedRectangle(cornerRadius: 11))
                        }
                        Button {
                            showManual = true
                        } label: {
                            Label("اسم", systemImage: "pencil")
                                .font(.subheadline.weight(.bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 11)
                                .background(MFColors.surface)
                                .foregroundStyle(MFColors.navy)
                                .overlay(RoundedRectangle(cornerRadius: 11).stroke(MFColors.muted.opacity(0.25), lineWidth: 1))
                                .clipShape(RoundedRectangle(cornerRadius: 11))
                        }
                    }

                    if let error {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(MFColors.danger)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }

                    if lines.isEmpty {
                        Text("امسح الباركود أو اكتب اسم المنتج ثم حدد العدد")
                            .font(.caption)
                            .foregroundStyle(MFColors.muted)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                    } else {
                        ForEach(lines) { line in
                            HStack {
                                Button {
                                    lines.removeAll { $0.id == line.id }
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundStyle(MFColors.danger)
                                }
                                Text("\(MFFormat.money(line.subtotal))")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(MFColors.gold)
                                Spacer()
                                VStack(alignment: .trailing, spacing: 3) {
                                    Text(line.name)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(MFColors.navy)
                                    Text(lineMeta(line))
                                        .font(.caption2)
                                        .foregroundStyle(MFColors.muted)
                                }
                            }
                            .padding(12)
                            .background(MFColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 16)
            }

            VStack(spacing: 8) {
                Text("الإجمالي \(MFFormat.money(total)) د.ع")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(MFColors.navy)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                Button {
                    Task { await submit() }
                } label: {
                    Group {
                        if saving {
                            ProgressView().tint(MFColors.gold)
                        } else {
                            Text("إرسال المردود")
                                .font(.subheadline.weight(.bold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(LinearGradient(colors: [MFColors.button, MFColors.buttonDark], startPoint: .top, endPoint: .bottom))
                    .foregroundStyle(MFColors.gold)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(MFColors.gold.opacity(0.14), lineWidth: 1))
                }
                .disabled(saving)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(LinearGradient(colors: [MFColors.bgTop, MFColors.bgBottom], startPoint: .top, endPoint: .bottom).ignoresSafeArea())
        .environment(\.layoutDirection, .rightToLeft)
        .task { await loadOffices() }
        .sheet(isPresented: $showScanner) {
            BarcodeScannerSheet { code in
                showScanner = false
                Task {
                    try? await Task.sleep(nanoseconds: 350_000_000)
                    await addFromBarcode(code)
                }
            } onError: { msg in
                showScanner = false
                error = msg
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showManual) {
            ManualReturnProductSheet { item, typed in
                showManual = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    if let item {
                        askQty(name: item.name, barcode: item.barcode, price: item.standardCost ?? 0)
                    } else {
                        askQty(name: typed, barcode: nil, price: 0)
                    }
                }
            }
            .environmentObject(appState)
        }
        .alert("الكمية", isPresented: $showQty) {
            TextField("العدد", text: $qtyText)
                .keyboardType(.decimalPad)
            Button("إضافة") { confirmQty() }
            Button("إلغاء", role: .cancel) {}
        } message: {
            Text(pendingName)
        }
    }

    private var header: some View {
        HStack {
            BackButton { dismiss() }
            Spacer()
            Text("مردود جديد")
                .font(.headline)
                .foregroundStyle(MFColors.navy)
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
    }

    private func field(_ title: String, text: Binding<String>) -> some View {
        TextField(title, text: text)
            .foregroundStyle(MFColors.navy)
            .tint(MFColors.gold)
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(MFColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 11))
            .overlay(RoundedRectangle(cornerRadius: 11).stroke(MFColors.muted.opacity(0.25), lineWidth: 1))
    }

    private var officeMatches: [BuyerSupplierOffice] {
        let q = vendor.trimmingCharacters(in: .whitespacesAndNewlines)
        if q.isEmpty { return Array(offices.prefix(12)) }
        return Array(offices.filter { $0.name.localizedCaseInsensitiveContains(q) }.prefix(12))
    }

    private var vendorSearchField: some View {
        VStack(alignment: .trailing, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(MFColors.muted)
                TextField("ابحث عن المذخر", text: $vendor)
                    .foregroundStyle(MFColors.navy)
                    .tint(MFColors.gold)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .focused($vendorFocused)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(MFColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 11))
            .overlay(RoundedRectangle(cornerRadius: 11).stroke(MFColors.muted.opacity(0.25), lineWidth: 1))

            if vendorFocused && !officeMatches.isEmpty {
                VStack(spacing: 0) {
                    ForEach(officeMatches) { office in
                        Button {
                            vendor = office.name
                            vendorFocused = false
                        } label: {
                            Text(office.name)
                                .font(.subheadline)
                                .foregroundStyle(MFColors.navy)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                        }
                        if office.id != officeMatches.last?.id {
                            Divider().overlay(MFColors.muted.opacity(0.2))
                        }
                    }
                }
                .background(MFColors.surfaceSoft)
                .clipShape(RoundedRectangle(cornerRadius: 11))
                .overlay(RoundedRectangle(cornerRadius: 11).stroke(MFColors.gold.opacity(0.12), lineWidth: 1))
            }
        }
    }

    private func loadOffices() async {
        guard let api = appState.api else { return }
        offices = (try? await api.buyerSuppliers()) ?? []
    }

    private func lineMeta(_ line: DraftReturnLine) -> String {
        var s = "عدد \(MFFormat.money(line.qty))"
        if let bc = line.barcode, !bc.isEmpty { s += " · \(bc)" }
        return s
    }

    private func askQty(name: String, barcode: String?, price: Double) {
        pendingName = name
        pendingBarcode = barcode
        pendingPrice = price
        qtyText = "1"
        showQty = true
    }

    private func confirmQty() {
        let qty = MFFormat.westernDouble(qtyText) ?? 0
        let name = pendingName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard qty > 0, !name.isEmpty else { return }
        lines.append(DraftReturnLine(name: name, barcode: pendingBarcode, qty: qty, unitPrice: pendingPrice))
    }

    private func addFromBarcode(_ code: String) async {
        guard let api = appState.api else {
            askQty(name: code, barcode: code, price: 0)
            return
        }
        do {
            if let found = try await api.buyerInventoryByBarcode(code) {
                askQty(name: found.name, barcode: found.barcode, price: found.standardCost ?? 0)
            } else {
                askQty(name: code, barcode: code, price: 0)
            }
        } catch {
            askQty(name: code, barcode: code, price: 0)
        }
    }

    private func submit() async {
        error = nil
        let vendorName = vendor.trimmingCharacters(in: .whitespacesAndNewlines)
        if vendorName.isEmpty {
            error = "اكتب اسم المذخر"
            return
        }
        if lines.isEmpty {
            error = "أضف منتجاً واحداً على الأقل"
            return
        }
        guard let api = appState.api else {
            error = "تعذّر الاتصال بالخادم"
            return
        }
        saving = true
        defer { saving = false }
        do {
            _ = try await api.createPurchaseReturn(
                vendorName: vendorName,
                invoiceNo: invoiceNo.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
                lines: lines.map {
                    PurchaseReturnLineInput(barcode: $0.barcode, productName: $0.name, qty: $0.qty)
                }
            )
            onSaved()
        } catch {
            self.error = (error as? LocalizedError)?.errorDescription ?? "تعذّر الحفظ"
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}

private struct ManualReturnProductSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    let onPick: (InventoryItem?, String) -> Void

    @State private var name = ""
    @State private var suggestions: [InventoryItem] = []
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button("إلغاء") { dismiss() }
                    .foregroundStyle(MFColors.muted)
                Spacer()
                Text("اسم المنتج")
                    .font(.headline)
                    .foregroundStyle(MFColors.navy)
            }
            TextField("اكتب الاسم", text: $name)
                .foregroundStyle(MFColors.navy)
                .tint(MFColors.gold)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(MFColors.surfaceSoft)
                .clipShape(RoundedRectangle(cornerRadius: 11))
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(suggestions) { item in
                        Button {
                            onPick(item, item.name)
                        } label: {
                            Text(item.name)
                                .foregroundStyle(MFColors.navy)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .padding(12)
                                .background(MFColors.surfaceSoft)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
            }
            Button {
                let typed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                if !typed.isEmpty { onPick(nil, typed) }
            } label: {
                Text("متابعة")
                    .font(.subheadline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(MFColors.button)
                    .foregroundStyle(MFColors.gold)
                    .clipShape(RoundedRectangle(cornerRadius: 11))
            }
            .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(16)
        .background(MFColors.bgTop.ignoresSafeArea())
        .environment(\.layoutDirection, .rightToLeft)
        .onChange(of: name) { value in
            searchTask?.cancel()
            let q = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard q.count >= 2 else {
                suggestions = []
                return
            }
            searchTask = Task {
                try? await Task.sleep(nanoseconds: 280_000_000)
                if Task.isCancelled { return }
                suggestions = (try? await appState.api?.buyerInventory(q: q)) ?? []
            }
        }
    }
}
