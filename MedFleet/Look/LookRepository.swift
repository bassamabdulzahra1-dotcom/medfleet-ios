import Foundation
import Observation

@MainActor
protocol MedFleetRepository: AnyObject {
    func monthSummary(year: Int, month: Int) async -> MonthSummary
    func sessions(year: Int, month: Int) async -> [LookSession]
    func session(id: String) async -> LookSession?
    func products() async -> [LookProduct]
    func purchaseReturns() async -> [LookReturn]

    func myAttendanceToday(_ user: AppUser) async -> AttendanceRecord
    func registerAttendance(_ user: AppUser, action: AttendanceAction, at: Date, lat: Double?, lng: Double?) async throws -> AttendanceRecord
    func teamAttendance(day: Date) async -> [AttendanceRecord]
}

@Observable
final class AppStore {
    var repo: MedFleetRepository
    var user: AppUser?
    var attendanceVersion = 0

    init(repo: MedFleetRepository, user: AppUser? = nil) {
        self.repo = repo
        self.user = user
    }
}

enum ScanMode: Hashable { case invoice, barcode }

enum Route: Hashable {
    case scanner(ScanMode)
    case stocktake
    case returns
    case returnNew
    case session(LookSession)
    case team
}

@Observable
final class Router {
    var path: [Route] = []
    func push(_ r: Route) { path.append(r) }
    func pop() { if !path.isEmpty { path.removeLast() } }
    func reset() { path.removeAll() }
}

extension User {
    func toAppUser() -> AppUser {
        let employee = appRole.lowercased() == "employee"
        return AppUser(
            id: id,
            name: name.isEmpty ? email : name,
            email: email,
            role: employee ? .employee : .admin,
            jobTitle: employee ? "صيدلي" : "مدير · صيدلية"
        )
    }
}
