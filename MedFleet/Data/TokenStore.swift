import Foundation
import Security

@MainActor
final class TokenStore: ObservableObject {
    @Published private(set) var token: String?
    @Published private(set) var user: User?

    private let service = "net.medfleet.rep"

    init() { load() }

    var isLoggedIn: Bool { token != nil && !(token?.isEmpty ?? true) }

    func save(session: LoginResponse) {
        token = session.token
        user = session.user
        KeychainHelper.set(session.token, service: service, account: "token")
        if let refresh = session.refreshToken {
            KeychainHelper.set(refresh, service: service, account: "refresh")
        }
        if let data = try? JSONEncoder().encode(session.user) {
            UserDefaults.standard.set(data, forKey: "mf_user")
        }
    }

    func updateAccessToken(_ newToken: String) {
        token = newToken
        KeychainHelper.set(newToken, service: service, account: "token")
    }

    func refreshTokenValue() -> String? {
        KeychainHelper.get(service: service, account: "refresh")
    }

    func clear() {
        token = nil
        user = nil
        KeychainHelper.delete(service: service, account: "token")
        KeychainHelper.delete(service: service, account: "refresh")
        UserDefaults.standard.removeObject(forKey: "mf_user")
    }

    private func load() {
        token = KeychainHelper.get(service: service, account: "token")
        if let data = UserDefaults.standard.data(forKey: "mf_user"),
           let u = try? JSONDecoder().decode(User.self, from: data) {
            user = u
        }
    }
}

enum KeychainHelper {
    static func set(_ value: String, service: String, account: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
        var add = query
        add[kSecValueData as String] = data
        SecItemAdd(add as CFDictionary, nil)
    }

    static func get(service: String, account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data,
              let str = String(data: data, encoding: .utf8) else { return nil }
        return str
    }

    static func delete(service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
