import Foundation

enum AppRole: Hashable { case admin, employee }

struct AppUser: Hashable, Identifiable {
    let id: String
    let name: String
    let email: String
    let role: AppRole
    let jobTitle: String

    var isAdmin: Bool { role == .admin }
    var initial: String { String(name.prefix(1)).uppercased() }
}

struct LookProduct: Hashable, Identifiable {
    var id: String { name }
    let name: String
    let sellPrice: Int
    var generic: String? = nil
    var stock: Int? = nil
    var cost: Int? = nil
    var barcode: String? = nil

    var isLowStock: Bool { (stock ?? Int.max) <= 1 }
}

struct LookOrderLine: Hashable {
    let name: String
    let qty: Double
    let unitPrice: Int
    var total: Int { Int((qty * Double(unitPrice)).rounded()) }
}

struct LookOrder: Hashable, Identifiable {
    var id: String { ref }
    let ref: String
    let time: Date
    let lines: [LookOrderLine]
    var customer = "عميل نقدي"
    var total: Int { lines.reduce(0) { $0 + $1.total } }
}

struct LookSession: Hashable, Identifiable {
    let id: String
    let openedBy: String
    let openedAt: Date
    let invoiceCount: Int
    let total: Int
    var closedBy: String? = nil
    var closedAt: Date? = nil
    var posAmount: Int? = nil
    var outsideAmount: Int? = nil
    var orders: [LookOrder] = []

    var isClosed: Bool { closedAt != nil || closedBy != nil }
    var staffLabel: String {
        guard let closedBy, closedBy != openedBy else { return openedBy }
        return "\(openedBy) ← \(closedBy)"
    }
}

struct MonthSummary: Hashable {
    let sessions: Int
    let invoices: Int
    let posAmount: Int
    let total: Int

    var outsideAmount: Int { total - posAmount }
    var posShare: Double { total == 0 ? 0 : Double(posAmount) / Double(total) }

    static let empty = MonthSummary(sessions: 0, invoices: 0, posAmount: 0, total: 0)
}

struct LookReturn: Hashable, Identifiable {
    var id: String { ref }
    let vendor: String
    let ref: String
    let invoiceNo: String
    let amount: Int
}

enum AttendanceStatus { case present, late, absent }
enum AttendanceAction: Hashable { case checkIn, checkOut }

struct ShiftTime: Hashable {
    let hour: Int
    let minute: Int
}

struct AttendanceRecord: Hashable, Identifiable {
    var id: String { employeeId }
    let employeeId: String
    let employeeName: String
    let jobTitle: String
    let shiftStart: ShiftTime
    var checkIn: Date? = nil
    var checkOut: Date? = nil
    var graceMinutes = 15

    var status: AttendanceStatus {
        guard let checkIn else { return .absent }
        let cal = Calendar.current
        var c = cal.dateComponents([.year, .month, .day], from: checkIn)
        c.hour = shiftStart.hour
        c.minute = shiftStart.minute
        guard let start = cal.date(from: c) else { return .present }
        return checkIn > start.addingTimeInterval(Double(graceMinutes) * 60) ? .late : .present
    }

    func worked(until now: Date) -> TimeInterval? {
        guard let checkIn else { return nil }
        return (checkOut ?? now).timeIntervalSince(checkIn)
    }

    var shiftText: String {
        let h = shiftStart.hour % 12 == 0 ? 12 : shiftStart.hour % 12
        return "\(h):" + String(format: "%02d", shiftStart.minute) + (shiftStart.hour < 12 ? " ص" : " م")
    }
}
