import Foundation

@MainActor
final class LocalAttendanceStore {
    private let key = "mf_look_attendance"
    private let cal = Calendar.current

    func today(_ user: AppUser) -> AttendanceRecord {
        records(for: Date()).first(where: { $0.employeeId == user.id })
            ?? AttendanceRecord(employeeId: user.id, employeeName: user.name, jobTitle: user.jobTitle, shiftStart: ShiftTime(hour: 9, minute: 0))
    }

    func put(_ record: AttendanceRecord, day: Date = Date()) {
        var list = records(for: day).filter { $0.employeeId != record.employeeId }
        list.append(record)
        persist(list, day: day)
    }

    func save(_ user: AppUser, action: AttendanceAction, at: Date) -> AttendanceRecord {
        var list = records(for: at)
        var current = list.first(where: { $0.employeeId == user.id })
            ?? AttendanceRecord(employeeId: user.id, employeeName: user.name, jobTitle: user.jobTitle, shiftStart: ShiftTime(hour: 9, minute: 0))
        if action == .checkIn {
            current.checkIn = at
        } else {
            current.checkOut = at
        }
        list.removeAll { $0.employeeId == user.id }
        list.append(current)
        persist(list, day: at)
        return current
    }

    func team(_ day: Date) -> [AttendanceRecord] { records(for: day) }

    private func records(for day: Date) -> [AttendanceRecord] {
        guard let data = UserDefaults.standard.data(forKey: storageKey(day)),
              let rows = try? JSONDecoder().decode([Stored].self, from: data)
        else { return [] }
        return rows.map { $0.record }
    }

    private func persist(_ list: [AttendanceRecord], day: Date) {
        let rows = list.map { Stored($0) }
        if let data = try? JSONEncoder().encode(rows) {
            UserDefaults.standard.set(data, forKey: storageKey(day))
        }
    }

    private func storageKey(_ day: Date) -> String {
        let c = cal.dateComponents([.year, .month, .day], from: day)
        return "\(key)-\(c.year ?? 0)-\(c.month ?? 0)-\(c.day ?? 0)"
    }

    private struct Stored: Codable {
        var employeeId: String
        var employeeName: String
        var jobTitle: String
        var shiftHour: Int
        var shiftMinute: Int
        var checkIn: Date?
        var checkOut: Date?

        init(_ r: AttendanceRecord) {
            employeeId = r.employeeId
            employeeName = r.employeeName
            jobTitle = r.jobTitle
            shiftHour = r.shiftStart.hour
            shiftMinute = r.shiftStart.minute
            checkIn = r.checkIn
            checkOut = r.checkOut
        }

        var record: AttendanceRecord {
            AttendanceRecord(
                employeeId: employeeId,
                employeeName: employeeName,
                jobTitle: jobTitle,
                shiftStart: ShiftTime(hour: shiftHour, minute: shiftMinute),
                checkIn: checkIn,
                checkOut: checkOut
            )
        }
    }
}

@MainActor
final class LiveLookRepository: MedFleetRepository {
    private let appState: AppState
    private let attendance = LocalAttendanceStore()
    private let baghdad = TimeZone(identifier: "Asia/Baghdad") ?? .current

    init(appState: AppState) {
        self.appState = appState
    }

    private var api: APIClient? { appState.api }

    func monthSummary(year: Int, month: Int) async -> MonthSummary {
        let list = await sessions(year: year, month: month)
        if list.isEmpty { return .empty }
        return MonthSummary(
            sessions: list.count,
            invoices: list.reduce(0) { $0 + $1.invoiceCount },
            posAmount: list.reduce(0) { $0 + ($1.posAmount ?? 0) },
            total: list.reduce(0) { $0 + $1.total }
        )
    }

    func sessions(year: Int, month: Int) async -> [LookSession] {
        guard let api else { return [] }
        let ym = String(format: "%04d-%02d", year, month)
        let list = (try? await api.buyerPosSessions(month: ym)) ?? []
        return list.map { $0.toLook() }
    }

    func session(id: String) async -> LookSession? {
        guard let api else { return nil }
        return try? await api.buyerPosSession(id: id).toLook()
    }

    func products() async -> [LookProduct] {
        guard let api else { return [] }
        let items = (try? await api.buyerInventory(q: nil)) ?? []
        return items.map {
            LookProduct(
                name: $0.name,
                sellPrice: Int(($0.salePrice ?? 0).rounded()),
                generic: $0.scientificName,
                stock: $0.qtyOnHand.map { Int($0.rounded()) },
                cost: $0.standardCost.map { Int($0.rounded()) },
                barcode: $0.barcode
            )
        }
    }

    func purchaseReturns() async -> [LookReturn] {
        guard let api else { return [] }
        let items = (try? await api.buyerPurchaseReturns()) ?? []
        return items.map {
            LookReturn(
                vendor: ($0.vendorName?.isEmpty == false ? $0.vendorName! : "مورد"),
                ref: ($0.ref?.isEmpty == false ? $0.ref! : $0.id),
                invoiceNo: ($0.invoiceNo?.isEmpty == false ? $0.invoiceNo! : "—"),
                amount: Int($0.amountTotal.rounded())
            )
        }
    }

    func myAttendanceToday(_ user: AppUser) async -> AttendanceRecord {
        if let dto = try? await api?.buyerAttendanceToday() {
            let mapped = dto.toRecord(user: user)
            attendance.put(mapped)
            return mapped
        }
        return attendance.today(user)
    }

    func registerAttendance(_ user: AppUser, action: AttendanceAction, at: Date) async throws -> AttendanceRecord {
        let actionStr = action == .checkIn ? "check_in" : "check_out"
        guard let api else {
            return attendance.save(user, action: action, at: at)
        }
        let dto = try await api.buyerAttendancePunch(action: actionStr)
        let mapped = dto.toRecord(user: user)
        attendance.put(mapped)
        return mapped
    }

    func teamAttendance(day: Date) async -> [AttendanceRecord] {
        let fmt = DateFormatter()
        fmt.calendar = Calendar(identifier: .gregorian)
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.timeZone = TimeZone(identifier: "Asia/Baghdad")
        fmt.dateFormat = "yyyy-MM-dd"
        if let list = try? await api?.buyerAttendanceTeam(day: fmt.string(from: day)) {
            return list.map { $0.toRecord() }
        }
        return attendance.team(day)
    }
}

private extension AttendanceDayDTO {
    func toRecord(user: AppUser? = nil) -> AttendanceRecord {
        AttendanceRecord(
            employeeId: userId ?? user?.id ?? "",
            employeeName: (employeeName?.isEmpty == false ? employeeName! : (user?.name ?? "")),
            jobTitle: (jobTitle?.isEmpty == false ? jobTitle! : (user?.jobTitle ?? "")),
            shiftStart: parseShift(shiftStart),
            checkIn: parseOptionalDt(checkIn),
            checkOut: parseOptionalDt(checkOut)
        )
    }
}

private func parseShift(_ raw: String?) -> ShiftTime {
    let parts = (raw ?? "09:00").split(separator: ":")
    let h = Int(parts.first ?? "9") ?? 9
    let m = Int(parts.dropFirst().first ?? "0") ?? 0
    return ShiftTime(hour: h, minute: m)
}

private extension PosSession {
    func toLook() -> LookSession {
        LookSession(
            id: id,
            openedBy: (openedBy?.isEmpty == false ? openedBy! : "—"),
            openedAt: parseDt(openedAt),
            invoiceCount: invoiceCount,
            total: Int(totalSales.rounded()),
            closedBy: closedBy,
            closedAt: closedAt.map(parseDt),
            posAmount: Int(posSalesTotal.rounded()),
            outsideAmount: Int(outsideSales.rounded()),
            orders: invoices.map { inv in
                LookOrder(
                    ref: (inv.ref?.isEmpty == false ? inv.ref! : inv.id),
                    time: parseDt(inv.createdAt),
                    lines: inv.lines.map {
                        LookOrderLine(
                            name: $0.productName.isEmpty ? "صنف" : $0.productName,
                            qty: $0.qty,
                            unitPrice: Int($0.unitPrice.rounded())
                        )
                    },
                    customer: (inv.customerName?.isEmpty == false ? inv.customerName! : "عميل نقدي")
                )
            }
        )
    }
}

private func parseOptionalDt(_ raw: String?) -> Date? {
    guard let raw, !raw.isEmpty else { return nil }
    return parseDt(raw)
}

private func parseDt(_ raw: String?) -> Date {
    guard let raw, !raw.isEmpty else { return Date() }
    let iso = ISO8601DateFormatter()
    iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let d = iso.date(from: raw) { return d }
    iso.formatOptions = [.withInternetDateTime]
    if let d = iso.date(from: raw) { return d }
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    f.timeZone = TimeZone(identifier: "Asia/Baghdad")
    return f.date(from: String(raw.prefix(19))) ?? Date()
}
