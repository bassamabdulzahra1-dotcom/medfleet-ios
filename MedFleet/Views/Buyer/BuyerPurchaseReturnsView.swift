import SwiftUI

struct BuyerPurchaseReturnsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var items: [PurchaseReturn] = []
    @State private var loading = true
    @State private var error: String?
    @State private var showEditor = false

    var body: some View {
        VStack(spacing: 0) {
            header
            if let error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(MFColors.danger)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
            }
            if loading && items.isEmpty {
                ProgressView().tint(MFColors.navy).padding(.top, 40)
                Spacer()
            } else if items.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "arrow.uturn.left")
                        .font(.title)
                        .foregroundStyle(MFColors.muted)
                    Text("لا يوجد مردود بعد — أضف مرتجعاً جديداً")
                        .font(.caption)
                        .foregroundStyle(MFColors.muted)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 48)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(items) { row in
                            VStack(alignment: .trailing, spacing: 6) {
                                Text(row.vendorName ?? "مذخر")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(MFColors.navy)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                Text(metaLine(row))
                                    .font(.caption)
                                    .foregroundStyle(MFColors.muted)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                Text("\(MFFormat.money(row.amountTotal)) د.ع")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(MFColors.gold)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                            .padding(14)
                            .background(MFColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(MFColors.gold.opacity(0.08), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            }
        }
        .background(LinearGradient(colors: [MFColors.bgTop, MFColors.bgBottom], startPoint: .top, endPoint: .bottom).ignoresSafeArea())
        .environment(\.layoutDirection, .rightToLeft)
        .task { await load() }
        .navigationDestination(isPresented: $showEditor) {
            BuyerPurchaseReturnEditorView {
                showEditor = false
                Task { await load() }
            }
            .toolbar(.hidden, for: .navigationBar)
            .environmentObject(appState)
        }
    }

    private var header: some View {
        HStack {
            BackButton { dismiss() }
            Spacer()
            Button {
                showEditor = true
            } label: {
                Image(systemName: "plus")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(MFColors.gold)
                    .frame(width: 44, height: 44)
                    .background(MFColors.surface)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(MFColors.gold.opacity(0.12), lineWidth: 1))
            }
            VStack(alignment: .trailing, spacing: 2) {
                Text("مردود الشراء")
                    .font(.headline)
                    .foregroundStyle(MFColors.navy)
                Text("مرتجعات المذخر")
                    .font(.caption2)
                    .foregroundStyle(MFColors.muted)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
    }

    private func metaLine(_ row: PurchaseReturn) -> String {
        var parts: [String] = []
        if let ref = row.ref, !ref.isEmpty { parts.append(ref) }
        if let inv = row.invoiceNo, !inv.isEmpty { parts.append("فاتورة \(inv)") }
        return parts.isEmpty ? "—" : parts.joined(separator: " · ")
    }

    private func load() async {
        if items.isEmpty { loading = true }
        error = nil
        guard let api = appState.api else {
            error = "تعذّر الاتصال بالخادم"
            loading = false
            return
        }
        do {
            items = try await api.buyerPurchaseReturns()
        } catch {
            self.error = (error as? LocalizedError)?.errorDescription ?? "تعذّر تحميل المردود"
        }
        loading = false
    }
}
