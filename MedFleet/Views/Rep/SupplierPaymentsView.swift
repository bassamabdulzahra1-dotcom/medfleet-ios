import SwiftUI

enum PaymentCalc {
    static func defaultDiscountPct(plan: PaymentPlan) -> Double {
        guard plan.plannedAmount > 0 else { return 0 }
        return (plan.discountAmount / plan.plannedAmount) * 100
    }

    static func grossShare(installment: PaymentInstallment, plan: PaymentPlan) -> Double {
        guard plan.netAmount > 0.01 else { return installment.amount }
        return installment.amount * plan.plannedAmount / plan.netAmount
    }

    static func installmentPayment(installment: PaymentInstallment, plan: PaymentPlan, pct: Double) -> (pay: Double, discExtra: Double) {
        let due = installment.amount - installment.discountAmount - installment.paidAmount
        guard due > 0 else { return (0, 0) }
        let gross = grossShare(installment: installment, plan: plan)
        let allocated = max(0, gross - installment.amount)
        let desired = (gross * min(max(pct, 0), 100) / 100 * 100).rounded() / 100
        let extra = min(max(desired - allocated, 0), due)
        let pay = ((due - extra) * 100).rounded() / 100
        return (pay, extra)
    }
}

struct PlanDraft: Identifiable {
    let id = UUID()
    let supplier: Supplier
    let amount: Double?
    let invoices: [PlanInvoice]
}

struct SupplierPaymentsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var connectivity: Connectivity

    @State private var suppliers: [Supplier] = []
    @State private var query = ""
    @State private var loading = true
    @State private var error: String?
    @State private var planDraft: PlanDraft?
    @State private var saving = false
    @State private var snack: String?
    @State private var invoicesFor: Supplier?
    @State private var pendingDraft: PlanDraft?

    var filtered: [Supplier] {
        let q = query.trimmingCharacters(in: .whitespaces)
        if q.isEmpty { return suppliers }
        return suppliers.filter { $0.name.localizedCaseInsensitiveContains(q) }
    }

    var body: some View {
        OpenModuleLayout(onBack: { dismiss() }) {
            VStack(spacing: 0) {
                if !connectivity.isOnline { OfflineBanner() }
                HStack {
                    Text("الموردين").font(.title2.bold()).foregroundStyle(MFColors.navy)
                    Spacer()
                    Button("تحديث") { Task { await load(force: true) } }.foregroundStyle(MFColors.accentDark)
                }
                .padding(.horizontal)
                .padding(.top, 60)
                .padding(.bottom, 4)

                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").foregroundStyle(MFColors.muted)
                    TextField("بحث باسم المورد", text: $query)
                        .foregroundStyle(MFColors.navy)
                        .tint(MFColors.accent)
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                    if !query.isEmpty {
                        Button { query = "" } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(MFColors.muted)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(MFColors.accentSoft)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                .padding(.bottom, 6)

                Group {
                    if loading && suppliers.isEmpty {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error, suppliers.isEmpty {
                    VStack(spacing: 12) {
                        Text(error).foregroundStyle(MFColors.danger)
                        Button("إعادة المحاولة") { Task { await load(force: true) } }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filtered.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "magnifyingglass").font(.title).foregroundStyle(MFColors.muted)
                        Text("لا يوجد مورد مطابق").foregroundStyle(MFColors.muted)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(filtered) { s in
                        supplierRow(s)
                    }
                    .listStyle(.plain)
                }
                }
            }
        }
        .task { await load(force: false) }
        .sheet(item: $planDraft) { draft in
            CreatePlanSheet(supplier: draft.supplier, saving: saving, initialAmount: draft.amount) { req in
                Task { await savePlan(req, invoices: draft.invoices) }
            }
        }
        .sheet(item: $invoicesFor, onDismiss: {
            if let d = pendingDraft {
                pendingDraft = nil
                DispatchQueue.main.async { planDraft = d }
            }
        }) { sup in
            SupplierInvoicesSheet(supplier: sup) { total, invs in
                pendingDraft = PlanDraft(supplier: sup, amount: total, invoices: invs)
                invoicesFor = nil
            }
        }
        .overlay(alignment: .bottom) {
            if let snack { Text(snack).padding().background(.ultraThinMaterial).clipShape(Capsule()).padding() }
        }
    }

    @ViewBuilder
    private func supplierRow(_ s: Supplier) -> some View {
        VStack(alignment: .trailing, spacing: 6) {
            Button { planDraft = PlanDraft(supplier: s, amount: nil, invoices: []) } label: {
                VStack(alignment: .trailing, spacing: 6) {
                    Text(s.name).font(.headline).foregroundStyle(MFColors.navy)
                    HStack {
                        Text("الدين: \(MFFormat.money(s.debtBalance)) د.ع").font(.caption).foregroundStyle(MFColors.muted)
                        Spacer()
                        if let d = s.lastPurchaseAt {
                            Text("آخر شراء: \(MFFormat.dueDate(d))")
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(MFColors.accentSoft)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button { invoicesFor = s } label: {
                Text("عرض الفواتير غير المسددة")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MFColors.accentDark)
            }
            .buttonStyle(.borderless)
        }
    }

    private func load(force: Bool) async {
        guard let api = appState.api else { return }
        if !force, let c = appState.cache.getSuppliers() { suppliers = c; loading = false; return }
        loading = suppliers.isEmpty
        do {
            suppliers = try await api.listSuppliers()
            appState.cache.putSuppliers(suppliers)
            appState.offline.save(suppliers, key: OfflineKey.suppliers)
            error = nil
        } catch let e {
            if let cached = appState.offline.load([Supplier].self, key: OfflineKey.suppliers), !cached.isEmpty {
                suppliers = cached
                error = nil
            } else if suppliers.isEmpty {
                self.error = e.localizedDescription
            }
        }
        loading = false
    }

    private func savePlan(_ req: CreatePaymentPlanRequest, invoices: [PlanInvoice]) async {
        guard let api = appState.api else { return }
        guard connectivity.isOnline else { snack = "لا يمكن إنشاء موعد بدون إنترنت"; return }
        saving = true
        defer { saving = false }
        let finalReq = invoices.isEmpty ? req : CreatePaymentPlanRequest(
            supplierId: req.supplierId,
            plannedAmount: req.plannedAmount,
            discountAmount: req.discountAmount,
            notes: req.notes,
            installments: req.installments,
            invoices: invoices
        )
        do {
            try await api.createPaymentPlan(finalReq)
            planDraft = nil
            appState.cache.invalidateSuppliers()
            appState.appointmentsRefresh += 1
            snack = "تمت إضافة الموعد — سدِّده من كارت المواعيد"
            await load(force: true)
        } catch {
            snack = error.localizedDescription
        }
    }
}

struct CreatePlanSheet: View {
    let supplier: Supplier
    let saving: Bool
    let initialAmount: Double?
    let onSave: (CreatePaymentPlanRequest) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var amount: String
    @State private var discountPct = "0"
    @State private var count = "1"
    @State private var firstDue = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var intervalDays = "30"

    init(supplier: Supplier, saving: Bool, initialAmount: Double? = nil, onSave: @escaping (CreatePaymentPlanRequest) -> Void) {
        self.supplier = supplier
        self.saving = saving
        self.initialAmount = initialAmount
        self.onSave = onSave
        let base = initialAmount ?? (supplier.debtBalance > 0 ? supplier.debtBalance : 0)
        _amount = State(initialValue: base > 0 ? String(format: "%.0f", base) : "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(supplier.name).fontWeight(.semibold)
                    Text("الدين: \(MFFormat.money(supplier.debtBalance)) د.ع").font(.caption).foregroundStyle(MFColors.muted)
                    if let initialAmount, initialAmount > 0 {
                        Text("مبلغ الفواتير المحددة: \(MFFormat.money(initialAmount)) د.ع")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(MFColors.navy)
                    }
                }

                Section("المبلغ") {
                    HStack {
                        Text("مبلغ التسديد").foregroundStyle(MFColors.muted)
                        Spacer()
                        TextField("0", text: $amount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: 170)
                    }
                    HStack {
                        Text("نسبة الخصم %").foregroundStyle(MFColors.muted)
                        Spacer()
                        TextField("0", text: $discountPct)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: 90)
                    }
                    if let planned = MFFormat.westernDouble(amount), let pct = MFFormat.westernDouble(discountPct), pct > 0 {
                        let disc = (planned * pct / 100 * 100).rounded() / 100
                        Text("الخصم \(MFFormat.money(disc)) د.ع — الصافي \(MFFormat.money(planned - disc)) د.ع")
                            .font(.caption).foregroundStyle(MFColors.gold)
                    }
                }

                Section("الأقساط (الافتراضي: تسديدة واحدة)") {
                    Stepper(value: Binding(
                        get: { min(max(Int(count) ?? 1, 1), 24) },
                        set: { count = String($0) }
                    ), in: 1...24) {
                        Text("عدد الأقساط: \(min(max(Int(count) ?? 1, 1), 24))")
                    }
                    if (Int(count) ?? 1) > 1 {
                        DatePicker("أول استحقاق", selection: $firstDue, in: Date()..., displayedComponents: .date)
                        HStack {
                            Text("أيام بين الأقساط").foregroundStyle(MFColors.muted)
                            Spacer()
                            TextField("30", text: $intervalDays)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: 80)
                        }
                    } else {
                        DatePicker("تاريخ الاستحقاق", selection: $firstDue, in: Date()..., displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("إضافة موعد تسديد")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("إلغاء") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("حفظ") { submit() }.disabled(saving)
                }
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }

    private func submit() {
        guard let planned = MFFormat.westernDouble(amount), planned > 0 else { return }
        let pct = min(max(MFFormat.westernDouble(discountPct) ?? 0, 0), 100)
        let disc = (planned * pct / 100 * 100).rounded() / 100
        let net = max(planned - disc, 0)
        let n = min(max(Int(count) ?? 1, 1), 24)
        let gap = max(Int(intervalDays) ?? 30, 1)
        let each = (net / Double(n) * 100).rounded() / 100
        var rem = net
        var inst: [InstallmentInput] = []
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"; fmt.locale = Locale(identifier: "en_US_POSIX")
        for i in 0..<n {
            let amt = i == n - 1 ? ((rem * 100).rounded() / 100) : each
            rem -= amt
            let date = Calendar.current.date(byAdding: .day, value: gap * i, to: firstDue) ?? firstDue
            inst.append(InstallmentInput(dueDate: fmt.string(from: date), amount: amt))
        }
        onSave(CreatePaymentPlanRequest(supplierId: supplier.id, plannedAmount: planned, discountAmount: disc, notes: nil, installments: inst, invoices: nil))
    }
}

struct SupplierInvoicesSheet: View {
    @EnvironmentObject var appState: AppState
    let supplier: Supplier
    let onPay: (Double, [PlanInvoice]) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var loading = true
    @State private var error: String?
    @State private var invoices: [SupplierInvoice] = []
    @State private var totalResidual = 0.0
    @State private var noOdooRef = false
    @State private var selectedIds: Set<String> = []

    private var selectedTotal: Double {
        invoices.filter { selectedIds.contains($0.id) }.reduce(0) { $0 + $1.amountResidual }
    }

    var body: some View {
        NavigationStack {
            Group {
                if loading {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error {
                    Text(error).foregroundStyle(MFColors.danger).padding().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if noOdooRef {
                    Text("هذا المورد غير مربوط بـ Odoo — اطلب من الأدمن المزامنة.")
                        .foregroundStyle(MFColors.muted).multilineTextAlignment(.center).padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if invoices.isEmpty {
                    Text("لا توجد فواتير غير مسددة 🎉")
                        .foregroundStyle(MFColors.navy).padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        Section {
                            ForEach(invoices) { inv in
                                invoiceRow(inv)
                            }
                        } header: {
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("إجمالي المتبقّي: \(MFFormat.money(totalResidual)) د.ع — \(invoices.count) فاتورة")
                                Text("اختر الفواتير التي تريد تسديدها داخل التطبيق")
                            }
                            .font(.caption).foregroundStyle(MFColors.muted)
                        } footer: {
                            Text("ملاحظة: التسديد يُسجَّل داخل التطبيق فقط ولا ينعكس على أودو.")
                                .font(.caption2).foregroundStyle(MFColors.muted)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .navigationDestination(for: SupplierInvoice.self) { inv in
                        InvoiceLinesView(invoice: inv)
                    }
                }
            }
            .navigationTitle("الفواتير غير المسددة")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("إغلاق") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(selectedIds.isEmpty ? "تسديد المحدد" : "تسديد المحدد (\(MFFormat.money(selectedTotal)))") {
                        let sel = invoices.filter { selectedIds.contains($0.id) }
                        onPay(selectedTotal, sel.map {
                            PlanInvoice(id: Int($0.id) ?? 0, name: $0.name, invoiceDate: $0.invoiceDate, amountResidual: $0.amountResidual)
                        })
                    }
                    .disabled(selectedIds.isEmpty || selectedTotal <= 0)
                }
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .task { await load() }
    }

    @ViewBuilder
    private func invoiceRow(_ inv: SupplierInvoice) -> some View {
        let isOn = selectedIds.contains(inv.id)
        HStack(alignment: .top, spacing: 10) {
            Button {
                if isOn { selectedIds.remove(inv.id) } else { selectedIds.insert(inv.id) }
            } label: {
                Image(systemName: isOn ? "checkmark.square.fill" : "square")
                    .foregroundStyle(isOn ? MFColors.gold : MFColors.muted)
            }
            .buttonStyle(.borderless)

            VStack(alignment: .trailing, spacing: 6) {
                HStack {
                    Text(inv.name ?? "—").font(.subheadline.weight(.semibold)).foregroundStyle(MFColors.navy)
                    Spacer()
                    Text(inv.paymentState == "partial" ? "مدفوعة جزئياً" : "غير مسددة")
                        .font(.caption)
                        .foregroundStyle(inv.paymentState == "partial" ? MFColors.gold : MFColors.danger)
                }
                if let ref = inv.ref, !ref.isEmpty {
                    HStack {
                        Text("الرقم المرجعي: \(ref)").font(.caption.weight(.semibold)).foregroundStyle(MFColors.gold)
                        Spacer()
                    }
                }
                HStack {
                    Text("التاريخ: \(inv.invoiceDate ?? "—")").font(.caption).foregroundStyle(MFColors.muted)
                    Spacer()
                    Text("المتبقّي: \(MFFormat.money(inv.amountResidual)) د.ع")
                        .font(.caption.weight(.semibold)).foregroundStyle(MFColors.navy)
                }
                NavigationLink(value: inv) {
                    HStack(spacing: 4) {
                        Image(systemName: "shippingbox")
                        Text("عرض المواد والمخزون")
                        Image(systemName: "chevron.left")
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MFColors.gold)
                }
                .buttonStyle(.borderless)
            }
        }
    }

    private func load() async {
        guard let api = appState.api else { loading = false; return }
        loading = true
        error = nil
        do {
            let r = try await api.getSupplierInvoices(supplierId: supplier.id)
            invoices = r.data
            totalResidual = r.totalResidual
            noOdooRef = r.noOdooRef
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }
}

extension Supplier: Hashable {
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (l: Supplier, r: Supplier) -> Bool { l.id == r.id }
}

extension SupplierInvoice: Hashable {
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (l: SupplierInvoice, r: SupplierInvoice) -> Bool { l.id == r.id }
}

struct InvoiceLinesView: View {
    @EnvironmentObject var appState: AppState
    let invoice: SupplierInvoice

    @State private var loading = true
    @State private var error: String?
    @State private var lines: [SupplierInvoiceLine] = []

    var body: some View {
        Group {
            if loading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error {
                Text(error).foregroundStyle(MFColors.danger).multilineTextAlignment(.center)
                    .padding().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if lines.isEmpty {
                Text("لا توجد مواد في هذه الفاتورة")
                    .foregroundStyle(MFColors.muted).padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    Section {
                        ForEach(lines) { line in
                            lineRow(line)
                        }
                    } header: {
                        Text("\(lines.count) مادة — الكمية بالفاتورة مقابل المخزون الحالي")
                            .font(.caption).foregroundStyle(MFColors.muted)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle(invoice.name ?? "مواد الفاتورة")
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.layoutDirection, .rightToLeft)
        .task { await load() }
    }

    @ViewBuilder
    private func lineRow(_ line: SupplierInvoiceLine) -> some View {
        VStack(alignment: .trailing, spacing: 6) {
            Text(line.name ?? "—")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MFColors.navy)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
            if let code = line.defaultCode, !code.isEmpty {
                Text(code).font(.caption2).foregroundStyle(MFColors.muted)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            HStack(spacing: 8) {
                qtyChip(title: "الكمية بالفاتورة",
                        value: MFFormat.money(line.quantity),
                        color: MFColors.navy)
                qtyChip(title: "المخزون الحالي",
                        value: line.stockQty != nil ? MFFormat.money(line.stockQty!) : "—",
                        color: stockColor(line))
            }
            HStack {
                Text("سعر الوحدة: \(MFFormat.money(line.priceUnit)) د.ع")
                    .font(.caption2).foregroundStyle(MFColors.muted)
                Spacer()
                Text("الإجمالي: \(MFFormat.money(line.priceSubtotal)) د.ع")
                    .font(.caption.weight(.semibold)).foregroundStyle(MFColors.navy)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func qtyChip(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(title).font(.caption2).foregroundStyle(MFColors.muted)
            Text(value).font(.subheadline.weight(.bold)).foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func stockColor(_ line: SupplierInvoiceLine) -> Color {
        guard let stock = line.stockQty else { return MFColors.muted }
        if stock <= 0 { return MFColors.danger }
        if stock < line.quantity { return MFColors.gold }
        return MFColors.navy
    }

    private func load() async {
        guard let api = appState.api else { loading = false; return }
        loading = true
        error = nil
        do {
            let r = try await api.getInvoiceLines(invoiceId: invoice.id)
            lines = r.data
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }
}
