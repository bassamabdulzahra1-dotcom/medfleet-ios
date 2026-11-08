import LocalAuthentication

enum BiometricResult { case success, failed, unavailable, error }

/// التحقق ببصمة الإصبع (Touch ID) أو الوجه (Face ID).
/// البصمة تثبت أن صاحب الهاتف هو من ضغط، لذلك يدخل كل موظف بحسابه على هاتفه
/// ويُسجَّل الحضور على حسابه في السيرفر.
enum BiometricAuth {
    static func authenticate(reason: String) async -> BiometricResult {
        let context = LAContext()
        context.localizedCancelTitle = "إلغاء"
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .unavailable
        }
        do {
            let ok = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
            return ok ? .success : .failed
        } catch let e as LAError {
            switch e.code {
            case .userCancel, .appCancel, .systemCancel, .authenticationFailed, .userFallback:
                return .failed
            case .biometryNotAvailable, .biometryNotEnrolled, .biometryLockout:
                return .unavailable
            default:
                return .error
            }
        } catch {
            return .error
        }
    }
}
