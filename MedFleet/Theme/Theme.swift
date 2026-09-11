import SwiftUI

enum MFColors {
    static let navy = Color(red: 243/255, green: 244/255, blue: 246/255)
    static let navy2 = Color(red: 148/255, green: 163/255, blue: 184/255)
    static let gold = Color(red: 203/255, green: 213/255, blue: 225/255)
    static let goldDark = Color(red: 148/255, green: 163/255, blue: 184/255)
    static let cream = Color(red: 20/255, green: 22/255, blue: 24/255)
    static let danger = Color(red: 248/255, green: 113/255, blue: 113/255)
    static let ok = Color(red: 148/255, green: 163/255, blue: 184/255)
    static let muted = Color(red: 156/255, green: 163/255, blue: 175/255)
    static let bgTop = Color(red: 20/255, green: 22/255, blue: 24/255)
    static let bgBottom = Color(red: 13/255, green: 15/255, blue: 17/255)
    static let surface = Color(red: 26/255, green: 28/255, blue: 32/255)
    static let surfaceSoft = Color(red: 34/255, green: 38/255, blue: 43/255)
    static let accent = gold
    static let accentDark = goldDark
    static let accentSoft = Color(red: 17/255, green: 19/255, blue: 21/255)
    static let ink = Color(red: 20/255, green: 22/255, blue: 24/255)
    static let button = Color(red: 42/255, green: 46/255, blue: 53/255)
    static let buttonDark = Color(red: 26/255, green: 28/255, blue: 35/255)
}

enum MFFormat {
    static func money(_ v: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        f.locale = Locale(identifier: "en_US")
        return f.string(from: NSNumber(value: v.rounded())) ?? "0"
    }

    static func dueDate(_ raw: String?) -> String {
        guard let raw, raw.count >= 10 else { return "—" }
        let part = String(raw.prefix(10))
        let inF = DateFormatter()
        inF.dateFormat = "yyyy-MM-dd"
        let outF = DateFormatter()
        outF.dateFormat = "yyyy-MM-dd"
        if let d = inF.date(from: part) { return outF.string(from: d) }
        return part
    }

    static func arabicDay(_ raw: String?) -> String {
        guard let raw, raw.count >= 10 else { return "—" }
        let inF = DateFormatter()
        inF.dateFormat = "yyyy-MM-dd"
        guard let d = inF.date(from: String(raw.prefix(10))) else { return "—" }
        let outF = DateFormatter()
        outF.locale = Locale(identifier: "ar")
        outF.dateFormat = "EEEE"
        return outF.string(from: d)
    }

    static func statusAr(_ status: String) -> String {
        switch status.lowercased() {
        case "paid": return "مسدّد"
        case "partial": return "جزئي"
        case "pending": return "معلق"
        case "active": return "نشط"
        case "completed": return "مكتمل"
        case "cancelled": return "ملغى"
        default: return status
        }
    }

    static func westernDouble(_ s: String) -> Double? {
        let map = s.unicodeScalars.map { scalar -> Character in
            let v = scalar.value
            switch v {
            case 0x0660...0x0669: return Character(String(v - 0x0660)) // Arabic-Indic ٠-٩
            case 0x06F0...0x06F9: return Character(String(v - 0x06F0)) // Extended Arabic-Indic ۰-۹
            default: return Character(scalar)
            }
        }
        return Double(String(map).replacingOccurrences(of: ",", with: ""))
    }
}

struct ModuleBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                LinearGradient(
                    colors: [MFColors.bgTop, MFColors.surfaceSoft, MFColors.bgBottom],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                    .ignoresSafeArea()
            )
    }
}

struct BackButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.right")
                .font(.body.weight(.semibold))
                .foregroundStyle(MFColors.gold)
                .frame(width: 44, height: 44)
                .background(MFColors.surface)
                .clipShape(Circle())
                .overlay(Circle().stroke(MFColors.gold.opacity(0.12), lineWidth: 1))
                .shadow(color: .black.opacity(0.35), radius: 6, y: 3)
        }
    }
}

struct OpenModuleLayout<Content: View>: View {
    let onBack: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack(alignment: .topTrailing) {
            content()
            BackButton(action: onBack)
                .padding(.top, 8)
                .padding(.trailing, 16)
        }
        .modifier(ModuleBackground())
        .environment(\.layoutDirection, .rightToLeft)
    }
}
