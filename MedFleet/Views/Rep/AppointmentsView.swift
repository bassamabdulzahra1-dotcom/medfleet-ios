import SwiftUI

struct AppointmentsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var connectivity: Connectivity

    @State private var items: [Reminder] = []
    @State private var totalAmount = 0.0
    @State private var loading = true
    @State private var expanded = Set<String>()
    @State private var busyId: String?
    @State private var cancelTarget: Reminder?
    @State private var snack: String?

    var groups: [(key: String, date: Date, items: [Reminder])] {
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
        let grouped = Dictionary(grouping: items) { String($0.dueDate.prefix(10)) }
        return grouped.compactMap { key, list -> (String, Date, [Reminder])? in
            guard let d = fmt.date(from: key) else { return nil }
            return (key, d, list.sorted { ($0.supplierName ?? "") < ($1.supplierName ?? "") })
        }.sorted { $0.date < $1.date }
    }

    var body: some View {
        OpenModuleLayout(onBack: { dismiss() }) {
            VStack(spacing: 0) {
                if !connectivity.isOnline { OfflineBanner() }
                Group {
                    if loading && items.isEmpty {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if items.isEmpty {
                    Text("لا توجد مواعيد مسجّلة").foregroundStyle(MFColors.muted).frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        Section {
                            Text("المواعيد").font(.title2.bold())
                            Text("\(items.count) موعد — \(groups.count) \(groups.count == 1 ? "يوم" : "أيام") — \(MFFormat.money(totalAmount)) د.ع")
                                .font(.caption).foregroundStyle(MFColors.muted)
                        }
                        ForEach(groups, id: \.key) { g in
                            Section {
                                if expanded.contains(g.key) {
                                    ForEach(g.items) { rem in
                                        ReminderRow(reminder: rem, busy: busyId == rem.id)
                                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                                Button(role: .destructive) { cancelTarget = rem } label: {
                                                    Label("إلغاء الموعد", systemImage: "calendar.badge.minus")
                                                }
                                            }
                                    }
                                }
                            } header: {
                                Button {
                                    if expanded.contains(g.key) { expanded.remove(g.key) } else { expanded.insert(g.key) }
                                } label: {
                                    HStack {
                                        Image(systemName: expanded.contains(g.key) ? "chevron.up" : "chevron.down")
                                        Spacer()
                                        VStack(alignment: .trailing) {
                                            Text("يوم \(MFFormat.arabicDay(g.key))").font(.headline)
                                            Text(MFFormat.dueDate(g.key)).font(.caption)
                                            Text("\(g.items.count) \(g.items.count == 1 ? "مكتب" : "مكاتب") — \(MFFormat.money(g.items.reduce(0) { $0 + $1.amount })) د.ع")
                                                .font(.subheadline.weight(.semibold)).foregroundStyle(MFColors.gold)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
                }
            }
        }
        .task(id: appState.appointmentsRefresh) { await load() }
        .overlay(alignment: .bottom) {
            if let snack { Text(snack).padding().background(.ultraThinMaterial).clipShape(Capsule()).padding() }
        }
        .alert("إلغاء الموعد؟", isPresented: Binding(get: { cancelTarget != nil }, set: { if !$0 { cancelTarget = nil } })) {
            Button("نعم، إلغاء", role: .destructive) {
                if let t = cancelTarget { Task { await cancel(t) } }
            }
            Button("تراجع", role: .cancel) {}
        } message: {
            if let t = cancelTarget {
                Text("إزالة موعد \(t.supplierName ?? "") بتاريخ \(MFFormat.dueDate(t.dueDate))")
            }
        }
    }

    private func load() async {
        guard let api = appState.api else { return }
        loading = items.isEmpty
        if let r = try? await api.getReminders() {
            items = r.data
            totalAmount = r.totalAmount ?? r.data.reduce(0) { $0 + $1.amount }
            appState.offline.save(r.data, key: OfflineKey.reminders)
        } else if items.isEmpty, let cached = appState.offline.load([Reminder].self, key: OfflineKey.reminders) {
            items = cached
            totalAmount = cached.reduce(0) { $0 + $1.amount }
        }
        loading = false
    }

    private func cancel(_ rem: Reminder) async {
        guard let api = appState.api else { return }
        guard connectivity.isOnline else { cancelTarget = nil; snack = "لا يمكن إلغاء الموعد بدون إنترنت"; return }
        busyId = rem.id
        let snap = items
        items.removeAll { $0.id == rem.id }
        totalAmount = items.reduce(0) { $0 + $1.amount }
        cancelTarget = nil
        do {
            try await api.cancelAppointment(id: rem.id)
            appState.appointmentsRefresh += 1
        } catch {
            items = snap
            totalAmount = snap.reduce(0) { $0 + $1.amount }
        }
        busyId = nil
    }
}

struct ReminderRow: View {
    let reminder: Reminder
    let busy: Bool

    var body: some View {
        if let planId = reminder.planId {
            NavigationLink(value: AppRoute.paymentPlan(planId)) {
                rowContent
            }
        } else {
            rowContent
        }
    }

    private var rowContent: some View {
        HStack {
            if busy { ProgressView() }
            Spacer()
            VStack(alignment: .trailing) {
                Text(reminder.supplierName ?? reminder.title ?? "موعد").font(.subheadline.weight(.semibold))
                Text("\(MFFormat.money(reminder.amount)) د.ع").font(.caption)
                Text(reminder.isOverdue == true ? "متأخر" : "قريب").font(.caption2).foregroundStyle(reminder.isOverdue == true ? MFColors.danger : MFColors.ok)
            }
        }
    }
}
