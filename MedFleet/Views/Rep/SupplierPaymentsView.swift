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

struct SupplierPaymentsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState

    @State private var suppliers: [Supplier] = []
    @State private var query = ""
    @State private var loading = true
    @State private var error: String?
    @State private var selected: Supplier?
    @State private var saving = false
    @State private var snack: String?

    var filtered: [Supplier] {
        let q = query.trimmingCharacters(in: .whitespaces)
        if q.isEmpty { return suppliers }
        return suppliers.filter { $0.name.localizedCaseInsensitiveContains(q) }
    }

    var body: some View {
        OpenModuleLayout(onBack: { dismiss() }) {
            Group {
                if loading && suppliers.isEmpty {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error, suppliers.isEmpty {
                    VStack(spacing: 12) {
                        Text(error).foregroundStyle(MFColors.danger)
                        Button("إعادة المحاولة") { Task { await load(force: true) } }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(filtered) { s in
                        Button { selected = s } label: {
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
                                            .background(MFColors.gold.opacity(0.15))
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .searchable(text: $query, prompt: "بحث باسم المورد")
                    .overlay(alignment: .top) {
                        HStack {
                            Text("الموردين").font(.title2.bold())
                            Spacer()
                            Button("تحديث") { Task { await load(force: true) } }.foregroundStyle(MFColors.gold)
                        }
                        .padding(.horizontal)
                        .padding(.top, 56)
                    }
                }
            }
        }
        .task { await load(force: false) }
        .sheet(item: $selected) { sup in
            CreatePlanSheet(supplier: sup, saving: saving) { req in
                Task { await savePlan(req) }
            }
        }
        .overlay(alignment: .bottom) {
            if let snack { Text(snack).padding().background(.ultraThinMaterial).clipShape(Capsule()).padding() }
        }
    }

    private func load(force: Bool) async {
        guard let api = appState.api else { return }
        if !force, let c = appState.cache.getSuppliers() { suppliers = c; loading = false; return }
        loading = suppliers.isEmpty
        do {
            suppliers = try await api.listSuppliers()
            appState.cache.putSuppliers(suppliers)
            error = nil
        } catch let e { if suppliers.isEmpty { self.error = e.localizedDescription } }
        loading = false
    }

    private func savePlan(_ req: CreatePaymentPlanRequest) async {
        guard let api = appState.api else { return }
        saving = true
        defer { saving = false }
        do {
            try await api.createPaymentPlan(req)
            selected = nil
            appState.cache.invalidateSuppliers()
            appState.appointmentsRefresh += 1
            snack = "تم التسديد — راجع كارت المواعيد"
            await load(force: true)
        } catch {
            snack = error.localizedDescription
        }
    }
}

struct CreatePlanSheet: View {
    let supplier: Supplier
    let saving: Bool
    let onSave: (CreatePaymentPlanRequest) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var amount: String
    @State private var discountPct = "0"
    @State private var count = "1"
    @State private var firstDue = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var intervalDays = "30"

    init(supplier: Supplier, saving: Bool, onSave: @escaping (CreatePaymentPlanRequest) -> Void) {
        self.supplier = supplier
        self.saving = saving
        self.onSave = onSave
        _amount = State(initialValue: supplier.debtBalance > 0 ? String(format: "%.0f", supplier.debtBalance) : "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(supplier.name).fontWeight(.semibold)
                    Text("الدين: \(MFFormat.money(supplier.debtBalance)) د.ع").font(.caption).foregroundStyle(MFColors.muted)
                }
                TextField("مبلغ التسديد", text: $amount).keyboardType(.decimalPad)
                TextField("خصم (%)", text: $discountPct).keyboardType(.decimalPad)
                if let planned = MFFormat.westernDouble(amount), let pct = MFFormat.westernDouble(discountPct), pct > 0 {
                    let disc = (planned * pct / 100 * 100).rounded() / 100
                    Text("يعادل \(MFFormat.money(disc)) د.ع — الصافي \(MFFormat.money(planned - disc)) د.ع").font(.caption)
                }
                TextField("عدد الأقساط", text: $count).keyboardType(.numberPad)
                DatePicker("أول استحقاق", selection: $firstDue, in: Date()..., displayedComponents: .date)
                TextField("أيام بين الأقساط", text: $intervalDays).keyboardType(.numberPad)
            }
            .navigationTitle("تسديد مورد")
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
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
        for i in 0..<n {
            let amt = i == n - 1 ? ((rem * 100).rounded() / 100) : each
            rem -= amt
            let date = Calendar.current.date(byAdding: .day, value: gap * i, to: firstDue) ?? firstDue
            inst.append(InstallmentInput(dueDate: fmt.string(from: date), amount: amt))
        }
        onSave(CreatePaymentPlanRequest(supplierId: supplier.id, plannedAmount: planned, discountAmount: disc, notes: nil, installments: inst))
    }
}

extension Supplier: Hashable {
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (l: Supplier, r: Supplier) -> Bool { l.id == r.id }
}
