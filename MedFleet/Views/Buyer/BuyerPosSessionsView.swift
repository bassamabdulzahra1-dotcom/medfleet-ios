import SwiftUI

struct BuyerPosSessionsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var sessions: [PosSession] = []
    @State private var current: PosSession?
    @State private var loading = true
    @State private var error: String?

    var body: some View {
        NavigationStack {
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
                if loading && sessions.isEmpty {
                    ProgressView().tint(MFColors.navy).padding(.top, 40)
                    Spacer()
                } else {
                    ScrollView {
                        VStack(alignment: .trailing, spacing: 12) {
                            totalsCard
                            if let current {
                                liveCard(current)
                            }
                            ForEach(sessions.filter { !$0.isOpen }) { s in
                                NavigationLink(value: s.id) { sessionRow(s) }
                                    .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 28)
                    }
                }
            }
            .background(LinearGradient(colors: [MFColors.bgTop, MFColors.bgBottom], startPoint: .top, endPoint: .bottom).ignoresSafeArea())
            .environment(\.layoutDirection, .rightToLeft)
            .navigationDestination(for: String.self) { id in
                BuyerPosSessionDetailView(sessionId: id)
                    .toolbar(.hidden, for: .navigationBar)
            }
            .task { await load() }
            .refreshable { await load() }
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
                Text("جلسات نقطة البيع")
                    .font(.headline)
                    .foregroundStyle(MFColors.navy)
                Text("تقارير المبيعات من الويب")
                    .font(.caption2)
                    .foregroundStyle(MFColors.muted)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
    }

    private var closedSessions: [PosSession] { sessions.filter { !$0.isOpen } }

    private var totalsCard: some View {
        let count = closedSessions.count
        let invoices = closedSessions.reduce(0) { $0 + $1.invoiceCount }
        let pos = closedSessions.reduce(0.0) { $0 + $1.posSalesTotal }
        let total = closedSessions.reduce(0.0) { $0 + $1.totalSales }
        return VStack(alignment: .trailing, spacing: 10) {
            Text("ملخص الجلسات المغلقة")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MFColors.navy)
            HStack {
                metric("جلسات", "\(count)")
                metric("فواتير", "\(invoices)")
                metric("POS", MFFormat.money(pos))
                metric("المجموع", MFFormat.money(total))
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 3, y: 1)
    }

    private func liveCard(_ s: PosSession) -> some View {
        NavigationLink(value: s.id) {
            VStack(alignment: .trailing, spacing: 8) {
                HStack {
                    Text("مفتوحة الآن")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(MFColors.ok)
                        .clipShape(Capsule())
                    Spacer()
                    Text("جلسة حالية")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(MFColors.navy)
                }
                Text("فتحها \(s.openedBy ?? "—") · \(fmtWhen(s.openedAt))")
                    .font(.caption)
                    .foregroundStyle(MFColors.muted)
                HStack {
                    Text("\(s.invoiceCount) فاتورة")
                        .font(.caption)
                        .foregroundStyle(MFColors.muted)
                    Spacer()
                    Text("\(MFFormat.money(s.totalSales)) د.ع")
                        .font(.body.weight(.bold))
                        .foregroundStyle(MFColors.navy)
                }
            }
            .padding(14)
            .background(MFColors.accentSoft)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    private func sessionRow(_ s: PosSession) -> some View {
        VStack(alignment: .trailing, spacing: 8) {
            HStack {
                Image(systemName: "chevron.left")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MFColors.muted)
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text(fmtWhen(s.openedAt))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(MFColors.navy)
                    Text("فتح: \(s.openedBy ?? "—")  ·  غلق: \(s.closedBy ?? "—")")
                        .font(.caption2)
                        .foregroundStyle(MFColors.muted)
                }
            }
            HStack {
                Text("\(s.invoiceCount) فاتورة")
                    .font(.caption)
                    .foregroundStyle(MFColors.muted)
                Spacer()
                Text("\(MFFormat.money(s.totalSales)) د.ع")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(MFColors.navy)
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 3, y: 1)
    }

    private func metric(_ title: String, _ value: String) -> some View {
        VStack(spacing: 3) {
            Text(value).font(.caption.weight(.bold)).foregroundStyle(MFColors.navy)
            Text(title).font(.caption2).foregroundStyle(MFColors.muted)
        }
        .frame(maxWidth: .infinity)
    }

    private func load() async {
        guard let api = appState.api else { return }
        loading = true
        error = nil
        do {
            async let list = api.buyerPosSessions()
            async let cur = api.buyerPosSessionCurrent()
            sessions = try await list
            current = try await cur
        } catch {
            self.error = "تعذّر تحميل جلسات نقطة البيع"
        }
        loading = false
    }
}

struct BuyerPosSessionDetailView: View {
    let sessionId: String
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var session: PosSession?
    @State private var error: String?

    var body: some View {
        VStack(spacing: 0) {
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
                Text("تفاصيل الجلسة")
                    .font(.headline)
                    .foregroundStyle(MFColors.navy)
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)

            if let error {
                Text(error).font(.caption).foregroundStyle(MFColors.danger).padding()
                Spacer()
            } else if let s = session {
                ScrollView {
                    VStack(alignment: .trailing, spacing: 12) {
                        summary(s)
                        ForEach(s.invoices) { inv in
                            invoiceCard(inv)
                        }
                        if s.invoices.isEmpty {
                            Text("لا توجد فواتير داخل هذه الجلسة")
                                .font(.caption)
                                .foregroundStyle(MFColors.muted)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 16)
                        }
                    }
                    .padding(16)
                }
            } else {
                ProgressView().tint(MFColors.navy).padding(.top, 40)
                Spacer()
            }
        }
        .background(LinearGradient(colors: [MFColors.bgTop, MFColors.bgBottom], startPoint: .top, endPoint: .bottom).ignoresSafeArea())
        .environment(\.layoutDirection, .rightToLeft)
        .task { await load() }
    }

    private func summary(_ s: PosSession) -> some View {
        VStack(alignment: .trailing, spacing: 8) {
            HStack {
                Text(s.isOpen ? "مفتوحة" : "مغلقة")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(s.isOpen ? MFColors.ok : MFColors.navy)
                    .clipShape(Capsule())
                Spacer()
                Text("فتحها \(s.openedBy ?? "—")")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MFColors.navy)
            }
            Text("الفتح: \(fmtWhen(s.openedAt))")
                .font(.caption).foregroundStyle(MFColors.muted)
            if let closed = s.closedAt {
                Text("الغلق: \(fmtWhen(closed)) · \(s.closedBy ?? "—")")
                    .font(.caption).foregroundStyle(MFColors.muted)
            }
            HStack {
                amountBox("فواتير", "\(s.invoiceCount)")
                amountBox("مبيعات POS", MFFormat.money(s.posSalesTotal))
                amountBox("خارج POS", MFFormat.money(s.outsideSales))
                amountBox("المجموع", MFFormat.money(s.totalSales))
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func invoiceCard(_ inv: PosSessionInvoice) -> some View {
        VStack(alignment: .trailing, spacing: 8) {
            HStack {
                Text("\(MFFormat.money(inv.amountTotal)) د.ع")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(MFColors.navy)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(inv.ref ?? "فاتورة")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(MFColors.navy)
                    Text("\(inv.customerName ?? "عميل نقدي") · \(fmtWhen(inv.createdAt))")
                        .font(.caption2)
                        .foregroundStyle(MFColors.muted)
                }
            }
            ForEach(inv.lines) { line in
                HStack {
                    Text(MFFormat.money(line.subtotal))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(MFColors.navy)
                    Spacer()
                    Text(line.productName)
                        .font(.caption)
                        .foregroundStyle(MFColors.navy)
                }
                Text("كمية \(MFFormat.money(line.qty)) × \(MFFormat.money(line.unitPrice))")
                    .font(.caption2)
                    .foregroundStyle(MFColors.muted)
            }
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func amountBox(_ title: String, _ value: String) -> some View {
        VStack(spacing: 3) {
            Text(value).font(.caption2.weight(.bold)).foregroundStyle(MFColors.navy)
            Text(title).font(.caption2).foregroundStyle(MFColors.muted)
        }
        .frame(maxWidth: .infinity)
    }

    private func load() async {
        guard let api = appState.api else { return }
        do { session = try await api.buyerPosSession(id: sessionId) }
        catch { self.error = "تعذّر تحميل تفاصيل الجلسة" }
    }
}

func fmtWhen(_ raw: String?) -> String {
    guard let raw, !raw.isEmpty else { return "—" }
    let iso = ISO8601DateFormatter()
    iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    let d = iso.date(from: raw) ?? ISO8601DateFormatter().date(from: raw)
    guard let d else { return String(raw.prefix(16)).replacingOccurrences(of: "T", with: " ") }
    let f = DateFormatter()
    f.locale = Locale(identifier: "ar")
    f.dateFormat = "d MMM، h:mm a"
    return f.string(from: d)
}
