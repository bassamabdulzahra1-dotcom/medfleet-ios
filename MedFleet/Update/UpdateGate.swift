import SwiftUI

/// إجبار التحديث: عند فتح التطبيق نسأل الخادم عن أقل نسخة مسموحة.
/// إذا نسختنا أقدم نعرض شاشة "حدّث التطبيق" بدل التطبيق (النسخ القديمة كانت تحفظ البصمة على الجهاز).
/// إذا الخادم ما يرد نكمل عادي.
struct UpdateInfo: Equatable {
    let minVersion: String
    let storeURL: URL?
    let message: String
}

enum UpdateCheck {
    static var currentVersion: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "0"
    }

    /// يقارن نسختين مثل 1.1.11 و 1.2.0 رقم رقم.
    static func isOlder(_ current: String, than min: String) -> Bool {
        let c = current.split(separator: ".").map { Int($0) ?? 0 }
        let m = min.split(separator: ".").map { Int($0) ?? 0 }
        for i in 0..<max(c.count, m.count) {
            let a = i < c.count ? c[i] : 0
            let b = i < m.count ? m[i] : 0
            if a != b { return a < b }
        }
        return false
    }

    static func fetch() async -> UpdateInfo? {
        guard let url = URL(string: "https://medfleet.net/api/v1/app/version") else { return nil }
        var req = URLRequest(url: url)
        req.timeoutInterval = 6
        guard let (data, res) = try? await URLSession.shared.data(for: req),
              (res as? HTTPURLResponse)?.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let ios = json["ios"] as? [String: Any],
              let min = ios["min_version"] as? String, !min.isEmpty
        else { return nil }
        let store = (ios["store_url"] as? String).flatMap { $0.hasPrefix("https://") ? URL(string: $0) : nil }
        let msg = (json["message"] as? String) ?? "نسخة التطبيق قديمة — حدّثها من المتجر حتى تكمل"
        return UpdateInfo(minVersion: min, storeURL: store, message: msg)
    }
}

struct UpdateGate<Content: View>: View {
    @ViewBuilder var content: () -> Content
    @State private var required: UpdateInfo?
    @Environment(\.openURL) private var openURL

    var body: some View {
        Group {
            if let info = required {
                VStack(spacing: 14) {
                    Text("تحديث مطلوب").font(.title2.bold())
                    Text(info.message).multilineTextAlignment(.center)
                    Text("نسختك \(UpdateCheck.currentVersion) — المطلوب \(info.minVersion) أو أحدث")
                        .font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    if let url = info.storeURL {
                        Button("حدّث الآن") { openURL(url) }
                            .buttonStyle(.borderedProminent)
                            .padding(.top, 8)
                    }
                }
                .padding(32)
                .environment(\.layoutDirection, .rightToLeft)
            } else {
                content()
            }
        }
        .task {
            if let info = await UpdateCheck.fetch(),
               UpdateCheck.isOlder(UpdateCheck.currentVersion, than: info.minVersion) {
                required = info
            }
        }
    }
}
