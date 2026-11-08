import SwiftUI
import UIKit

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

/// هوية MedFleet — "الصنوبر والشمبانيا".
enum MF {
    static let pine = Color(hex: 0x0B3B34)
    static let pineDeep = Color(hex: 0x08261F)
    static let gold = Color(hex: 0xC9A96E)
    static let goldText = Color(hex: 0x8B6A2F)
    static let goldTint = Color(hex: 0xF4ECDD)
    static let goldSoft = Color(hex: 0xE6D3AC)
    static let mint = Color(hex: 0x7FC8B4)
    static let mintTint = Color(hex: 0xE3F0EB)

    static let porcelain = Color(hex: 0xF5F3EF)
    static let sand = Color(hex: 0xE9E5DC)
    static let ink = Color(hex: 0x0E1A17)
    static let ink2 = Color(hex: 0x5B6763)
    static let ink3 = Color(hex: 0x6A7470)
    static let onPineMuted = Color(hex: 0xB7CCC5)
    static let line = Color(hex: 0x0E1A17, alpha: 0.07)

    static let success = Color(hex: 0x1F7A4D)
    static let successTint = Color(hex: 0xE3F1E9)
    static let successText = Color(hex: 0x1F6B44)
    static let warnTint = Color(hex: 0xFBEBDD)
    static let warnText = Color(hex: 0x8A4512)
    static let danger = Color(hex: 0xA3321E)
    static let dangerTint = Color(hex: 0xFBE8E3)
    static let dangerSoft = Color(hex: 0xE89A86)

    static let ring = Color(hex: 0xC9A96E, alpha: 0.2)
}

/// الخطوط: Alexandria للعناوين والأرقام، IBM Plex Sans Arabic للنصوص، Marcellus للشعار.
/// إن لم تُضف ملفات الخطوط يُستخدم خط النظام تلقائياً.
enum MFFont {
    /// الخط المتغيّر Alexandria: نأخذ اسمه الفعلي من النظام ثم نغيّر الوزن عبر .weight
    private static let alexandriaName: String? = UIFont.fontNames(forFamilyName: "Alexandria").first
    private static let hasPlex = UIFont(name: "IBMPlexSansArabic-Regular", size: 12) != nil
    private static let hasMarcellus = UIFont(name: "Marcellus-Regular", size: 12) != nil

    static func display(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        if let alexandriaName { return .custom(alexandriaName, size: size).weight(weight) }
        return .system(size: size, weight: weight, design: .default)
    }

    static func body(_ size: CGFloat = 14, _ weight: Font.Weight = .regular) -> Font {
        guard hasPlex else { return .system(size: size, weight: weight) }
        let name: String
        switch weight {
        case .medium: name = "IBMPlexSansArabic-Medium"
        case .semibold: name = "IBMPlexSansArabic-SemiBold"
        case .bold, .heavy, .black: name = "IBMPlexSansArabic-Bold"
        default: name = "IBMPlexSansArabic-Regular"
        }
        return .custom(name, size: size)
    }

    static func logo(_ size: CGFloat) -> Font {
        hasMarcellus ? .custom("Marcellus-Regular", size: size) : .system(size: size, weight: .regular, design: .serif)
    }
}

/// ظل ناعم موحّد للبطاقات.
extension View {
    func softShadow(_ radius: CGFloat = 14) -> some View {
        shadow(color: MF.ink.opacity(0.07), radius: radius, x: 0, y: 8)
    }

    func pineShadow() -> some View {
        shadow(color: MF.pine.opacity(0.3), radius: 22, x: 0, y: 16)
    }
}

/// تأثير ضغط خفيف للأزرار.
struct PressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
