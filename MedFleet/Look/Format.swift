import Foundation

/// تنسيق الأرقام والتواريخ بالعربية (أرقام لاتينية كما في التطبيق الحالي).

func money(_ value: Int) -> String {
    let digits = String(abs(value))
    var out = ""
    for (i, c) in digits.enumerated() {
        if i > 0 && (digits.count - i) % 3 == 0 { out.append(",") }
        out.append(c)
    }
    return value < 0 ? "-" + out : out
}

func moneyOrDash(_ value: Int?) -> String { value.map(money) ?? "—" }

func qtyText(_ q: Double) -> String {
    q.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(q)) : String(q)
}

/// Calendar.weekday: 1 = الأحد … 7 = السبت
private let arWeekdays = ["الأحد", "الاثنين", "الثلاثاء", "الأربعاء", "الخميس", "الجمعة", "السبت"]

let arMonths = [
    "كانون الثاني", "شباط", "آذار", "نيسان", "أيار", "حزيران",
    "تموز", "آب", "أيلول", "تشرين الأول", "تشرين الثاني", "كانون الأول",
]

private var cal: Calendar { Calendar.current }

func weekday(_ d: Date) -> String { arWeekdays[cal.component(.weekday, from: d) - 1] }

func hm(_ d: Date) -> String {
    let c = cal.dateComponents([.hour, .minute], from: d)
    let hour = c.hour ?? 0
    let h = hour % 12 == 0 ? 12 : hour % 12
    return "\(h):" + String(format: "%02d", c.minute ?? 0)
}

func amPm(_ d: Date) -> String { cal.component(.hour, from: d) < 12 ? "ص" : "م" }

func time12(_ d: Date) -> String { "\(hm(d)) \(amPm(d))" }

func time12OrDash(_ d: Date?) -> String { d.map(time12) ?? "—" }

func dayMonth(_ d: Date) -> String {
    "\(cal.component(.day, from: d)) \(arMonths[cal.component(.month, from: d) - 1])"
}

func fullDate(_ d: Date) -> String {
    let c = cal.dateComponents([.day, .month, .year], from: d)
    return "\(weekday(d))، \(c.day ?? 1) \(arMonths[(c.month ?? 1) - 1]) \(c.year ?? 2026)"
}

func durationText(_ seconds: TimeInterval) -> String {
    let total = Int(seconds) / 60
    let h = total / 60
    let m = total % 60
    return h == 0 ? "\(m)د" : "\(h)س \(m)د"
}

func greeting(_ d: Date) -> String { cal.component(.hour, from: d) < 12 ? "صباح الخير" : "مساء الخير" }

func makeDate(_ y: Int, _ m: Int, _ d: Int, _ h: Int, _ min: Int) -> Date {
    cal.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min)) ?? Date()
}
