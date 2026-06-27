import SwiftUI

enum MFColors {
    static let navy = Color(red: 0.04, green: 0.31, blue: 0.35)
    static let navy2 = Color(red: 0.03, green: 0.44, blue: 0.50)
    static let gold = Color(red: 0.05, green: 0.69, blue: 0.78)
    static let goldDark = Color(red: 0.02, green: 0.52, blue: 0.60)
    static let cream = Color(red: 0.98, green: 0.99, blue: 1.00)
    static let danger = Color(red: 0.72, green: 0.36, blue: 0.33)
    static let ok = Color(red: 0.04, green: 0.62, blue: 0.70)
    static let muted = Color(red: 0.42, green: 0.50, blue: 0.52)
    static let bgTop = Color(red: 0.99, green: 1.00, blue: 1.00)
    static let bgBottom = Color(red: 0.95, green: 0.99, blue: 1.00)
    static let surface = Color.white
    static let surfaceSoft = Color(red: 0.94, green: 0.99, blue: 1.00)
    static let accent = gold
    static let accentDark = goldDark
    static let accentSoft = Color(red: 0.88, green: 0.97, blue: 0.99)
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
                LinearGradient(colors: [MFColors.bgTop, MFColors.bgBottom], startPoint: .top, endPoint: .bottom)
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
                .foregroundStyle(MFColors.navy)
                .frame(width: 44, height: 44)
                .background(Color.white)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
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
