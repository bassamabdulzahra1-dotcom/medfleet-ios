import SwiftUI

enum MFColors {
    static let navy = Color(red: 14/255, green: 26/255, blue: 23/255)
    static let navy2 = Color(red: 91/255, green: 103/255, blue: 99/255)
    static let gold = Color(red: 201/255, green: 169/255, blue: 110/255)
    static let goldDark = Color(red: 139/255, green: 106/255, blue: 47/255)
    static let cream = Color(red: 245/255, green: 243/255, blue: 239/255)
    static let danger = Color(red: 163/255, green: 50/255, blue: 30/255)
    static let ok = Color(red: 31/255, green: 122/255, blue: 77/255)
    static let muted = Color(red: 91/255, green: 103/255, blue: 99/255)
    static let bgTop = Color(red: 245/255, green: 243/255, blue: 239/255)
    static let bgBottom = Color(red: 245/255, green: 243/255, blue: 239/255)
    static let surface = Color.white
    static let surfaceSoft = Color(red: 233/255, green: 229/255, blue: 220/255)
    static let accent = Color(red: 11/255, green: 59/255, blue: 52/255)
    static let accentDark = Color(red: 8/255, green: 38/255, blue: 31/255)
    static let accentSoft = Color(red: 227/255, green: 240/255, blue: 235/255)
    static let ink = Color(red: 14/255, green: 26/255, blue: 23/255)
    static let button = Color(red: 11/255, green: 59/255, blue: 52/255)
    static let buttonDark = Color(red: 8/255, green: 38/255, blue: 31/255)
    static let pine = Color(red: 11/255, green: 59/255, blue: 52/255)
    static let porcelain = Color(red: 245/255, green: 243/255, blue: 239/255)
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
            .background(MFColors.porcelain.ignoresSafeArea())
    }
}

struct BackButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.right")
                .font(.body.weight(.semibold))
                .foregroundStyle(MFColors.pine)
                .frame(width: 44, height: 44)
                .background(Color.white)
                .clipShape(Circle())
                .overlay(Circle().stroke(MFColors.gold.opacity(0.25), lineWidth: 1))
                .shadow(color: MFColors.ink.opacity(0.08), radius: 6, y: 3)
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
