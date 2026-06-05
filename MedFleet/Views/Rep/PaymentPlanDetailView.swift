import SwiftUI

struct PaymentPlanDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    let planId: String

    @State private var detail: PaymentPlanDetail?
    @State private var loading = true
    @State private var discountPct: [String: String] = [:]
    @State private var busyId: String?

    var body: some View {
        OpenModuleLayout(onBack: { dismiss() }) {
            Group {
                if loading && detail == nil {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let d = detail {
                    List {
                        Section {
                            Text(d.plan.supplierName ?? "جدول الدفع").font(.title3.bold())
                            Text("المبلغ \(MFFormat.money(d.plan.plannedAmount)) د.ع")
                            Text("الخصم: \(MFFormat.money(d.plan.discountAmount)) — بعد الخصم: \(MFFormat.money(d.plan.netAmount))")
                                .font(.caption)
                        }
                        ForEach(d.installments) { inst in
                            installmentSection(inst, plan: d.plan)
                        }
                    }
                    .listStyle(.insetGrouped)
                } else {
                    Text("لا توجد بيانات").frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .task { await load() }
    }

    @ViewBuilder
    private func installmentSection(_ inst: PaymentInstallment, plan: PaymentPlan) -> some View {
        let pct = MFFormat.westernDouble(discountPct[inst.id] ?? "") ?? PaymentCalc.defaultDiscountPct(plan: plan)
        let payInfo = PaymentCalc.installmentPayment(installment: inst, plan: plan, pct: pct)
        Section("قسط \(inst.seqNo) — \(MFFormat.dueDate(inst.dueDate))") {
            Text("المبلغ: \(MFFormat.money(PaymentCalc.grossShare(installment: inst, plan: plan))) د.ع")
            Text("المتبقي: \(MFFormat.money(inst.amount - inst.discountAmount - inst.paidAmount)) — \(MFFormat.statusAr(inst.status))")
                .font(.caption)
            if inst.status != "paid" && inst.status != "cancelled" {
                HStack {
                    TextField("خصم %", text: Binding(
                        get: { discountPct[inst.id] ?? String(format: "%.1f", PaymentCalc.defaultDiscountPct(plan: plan)) },
                        set: { discountPct[inst.id] = $0 }
                    ))
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    Button("−") {
                        let v = max(pct - 0.5, 0)
                        discountPct[inst.id] = String(format: "%.1f", v)
                    }
                    Button("+") {
                        let v = min(pct + 0.5, 100)
                        discountPct[inst.id] = String(format: "%.1f", v)
                    }
                }
                Button("تسديد \(MFFormat.money(payInfo.pay)) د.ع") {
                    Task { await pay(inst, paid: payInfo.pay, disc: payInfo.discExtra) }
                }
                .disabled(busyId == inst.id)
            }
        }
    }

    private func load() async {
        guard let api = appState.api else { return }
        loading = detail == nil
        if let d = try? await api.getPaymentPlan(id: planId) {
            detail = d
            let pct = PaymentCalc.defaultDiscountPct(plan: d.plan)
            discountPct = Dictionary(uniqueKeysWithValues: d.installments.map { ($0.id, String(format: "%.1f", pct)) })
        }
        loading = false
    }

    private func pay(_ inst: PaymentInstallment, paid: Double, disc: Double) async {
        guard let api = appState.api else { return }
        busyId = inst.id
        defer { busyId = nil }
        try? await api.payInstallment(id: inst.id, paid: paid, discount: disc)
        appState.settlementsRefresh += 1
        appState.appointmentsRefresh += 1
        appState.cache.invalidateSettlements()
        await load()
    }
}
