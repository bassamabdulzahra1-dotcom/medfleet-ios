import SwiftUI

struct BuyerInventoryView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var query = ""
    @State private var items: [InventoryItem] = []
    @State private var loading = true
    @State private var error: String?
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 0) {
            header

            searchField

            if !loading {
                Text("\(items.count) منتج")
                    .font(.caption)
                    .foregroundStyle(MFColors.muted)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 4)
            }

            content
        }
        .background(LinearGradient(colors: [MFColors.bgTop, MFColors.bgBottom], startPoint: .top, endPoint: .bottom).ignoresSafeArea())
        .environment(\.layoutDirection, .rightToLeft)
        .task { await load("") }
        .onChange(of: query) { newValue in
            searchTask?.cancel()
            searchTask = Task {
                try? await Task.sleep(nanoseconds: 350_000_000)
                if Task.isCancelled { return }
                await load(newValue)
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
            Text("المخزن")
                .font(.headline)
                .foregroundStyle(MFColors.navy)
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(MFColors.muted)
            TextField("ابحث بالاسم أو الباركود", text: $query)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(MFColors.muted.opacity(0.25), lineWidth: 1))
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var content: some View {
        if loading {
            Spacer()
            ProgressView().tint(MFColors.navy)
            Spacer()
        } else if let error {
            Spacer()
            Text(error).foregroundStyle(MFColors.muted)
            Spacer()
        } else if items.isEmpty {
            Spacer()
            Text("لا توجد منتجات").foregroundStyle(MFColors.muted)
            Spacer()
        } else {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(items) { p in
                        InventoryRow(item: p)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
    }

    private func load(_ q: String) async {
        guard let api = appState.api else { return }
        loading = true
        error = nil
        do {
            items = try await api.buyerInventory(q: q.isEmpty ? nil : q)
        } catch {
            self.error = "تعذّر تحميل المخزن."
        }
        loading = false
    }
}

private struct InventoryRow: View {
    let item: InventoryItem

    var body: some View {
        VStack(alignment: .trailing, spacing: 6) {
            Text(item.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MFColors.navy)
                .frame(maxWidth: .infinity, alignment: .trailing)

            if let sci = item.scientificName, !sci.isEmpty {
                Text(sci)
                    .font(.caption)
                    .foregroundStyle(MFColors.muted)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }

            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("بيع: \(MFFormat.money(item.salePrice ?? 0)) د.ع")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(MFColors.accentDark)
                    Text("كلفة: \(MFFormat.money(item.standardCost ?? 0))")
                        .font(.caption2)
                        .foregroundStyle(MFColors.muted)
                }
                Spacer()
                qtyBadge
            }

            if let bc = item.barcode, !bc.isEmpty {
                Text("باركود: \(bc)")
                    .font(.caption2)
                    .foregroundStyle(MFColors.muted)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 3, y: 1)
    }

    private var qtyBadge: some View {
        let qty = item.qtyOnHand ?? 0
        let color = qty > 0 ? MFColors.ok : MFColors.danger
        return Text("الرصيد: \(MFFormat.money(qty))")
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 9).padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}
