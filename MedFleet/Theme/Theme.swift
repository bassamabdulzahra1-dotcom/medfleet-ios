import SwiftUI

enum MFColors {
    static let navy = Color(red: 0.06, green: 0.10, blue: 0.14)
    static let navy2 = Color(red: 0.09, green: 0.13, blue: 0.18)
    static let gold = Color(red: 0.79, green: 0.66, blue: 0.30)
    static let goldDark = Color(red: 0.65, green: 0.52, blue: 0.22)
    static let cream = Color(red: 0.96, green: 0.96, blue: 0.93)
    static let danger = Color(red: 0.72, green: 0.36, blue: 0.33)
    static let ok = Color(red: 0.31, green: 0.55, blue: 0.37)
    static let muted = Color(red: 0.54, green: 0.50, blue: 0.43)
    static let bgTop = Color(red: 0.93, green: 0.91, blue: 0.96)
    static let bgBottom = Color(red: 0.97, green: 0.96, blue: 0.98)
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
        let map = s.map { ch -> Character in
            switch ch {
            case "٠"..."٩": return Character(String(Int(ch.asciiValue! - 1632)))
            case "۰"..."۹": return Character(String(Int(ch.asciiValue! - 1776)))
            default: return ch
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
