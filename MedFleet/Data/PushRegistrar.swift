import Foundation
import FirebaseMessaging

@MainActor
enum PushRegistrar {
    static func sync(api: APIClient?, tokenStore: TokenStore?) {
        guard tokenStore?.user?.canSeePos == true else { return }
        Messaging.messaging().token { token, _ in
            guard let token, !token.isEmpty else { return }
            Task { @MainActor in
                try? await api?.registerDeviceToken(token)
            }
        }
    }
}
