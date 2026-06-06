import Foundation

/// Persistent on-disk cache for read-only offline support.
/// Stores the last successful API payloads so screens can still render
/// data when the device has no connection. Read-only — never queues writes.
final class OfflineStore {
    private let dir: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        dir = base.appendingPathComponent("mf_offline", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    private func url(_ key: String) -> URL { dir.appendingPathComponent(key + ".json") }

    func save<T: Encodable>(_ value: T, key: String) {
        guard let data = try? encoder.encode(value) else { return }
        try? data.write(to: url(key), options: .atomic)
    }

    func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = try? Data(contentsOf: url(key)) else { return nil }
        return try? decoder.decode(type, from: data)
    }

    func clearAll() {
        try? FileManager.default.removeItem(at: dir)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }
}

enum OfflineKey {
    static let suppliers = "suppliers"
    static let settlements = "settlements"
    static let reminders = "reminders"
}
