import Foundation
import UserNotifications

@MainActor
final class PosSessionMonitor: ObservableObject {
    private var timer: Timer?
    private var lastAfter: String
    private var started = false

    init() {
        lastAfter = ISO8601DateFormatter().string(from: Date())
    }

    func start(appState: AppState) {
        guard !started else { return }
        started = true
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        timer = Timer.scheduledTimer(withTimeInterval: 20, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.poll(appState: appState)
            }
        }
        if let timer { RunLoop.main.add(timer, forMode: .common) }
        Task { await poll(appState: appState) }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        started = false
    }

    private func poll(appState: AppState) async {
        guard let api = appState.api else { return }
        do {
            let events = try await api.buyerPosSessionEvents(after: lastAfter)
            for ev in events {
                if ev.type == "opened" {
                    notify(
                        title: "تم فتح جلسة نقطة البيع",
                        body: "فتحها \(ev.cashier ?? "موظف") — تابع المبيعات من التطبيق"
                    )
                } else if ev.type == "closed" {
                    notify(
                        title: "تم إغلاق جلسة نقطة البيع",
                        body: "أغلقها \(ev.cashier ?? "موظف") · المجموع \(MFFormat.money(ev.amount)) د.ع"
                    )
                }
                if let at = ev.at { lastAfter = at }
            }
            if events.isEmpty {
                lastAfter = ISO8601DateFormatter().string(from: Date())
            }
        } catch {
            // لا نكسر التطبيق إذا فشل الاستعلام
        }
    }

    private func notify(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let req = UNNotificationRequest(
            identifier: "pos-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(req)
    }
}
