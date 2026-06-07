import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case http(Int, String?)
    case decoding(Error)
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "رابط غير صالح"
        case .http(let code, let msg): return msg ?? "خطأ (\(code))"
        case .decoding: return "خطأ في قراءة البيانات"
        case .unauthorized: return "انتهت الجلسة"
        }
    }
}

@MainActor
final class APIClient {
    static let baseURL = URL(string: "https://medfleet.net/api/v1/")!
    private let tokenStore: TokenStore
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private var refreshTask: Task<String?, Never>?

    init(tokenStore: TokenStore, session: URLSession = .shared) {
        self.tokenStore = tokenStore
        self.session = session
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }

    // MARK: - Auth

    func login(email: String, password: String) async throws -> LoginResponse {
        let body = LoginRequest(email: email, password: password)
        let res: LoginResponse = try await request(path: "auth/login", method: "POST", body: body, auth: false)
        tokenStore.save(session: res)
        return res
    }

    func logout() async {
        _ = try? await request(path: "auth/logout", method: "POST", body: Optional<String>.none as String?) as EmptyResponse
        tokenStore.clear()
    }

    // MARK: - Rep

    func listPharmacies() async throws -> [Pharmacy] {
        let r: PharmacyList = try await get("rep/pharmacies")
        return r.data
    }

    func createPharmacy(_ req: PharmacyCreateRequest) async throws -> Pharmacy {
        let r: PharmacyResponse = try await request(path: "rep/pharmacies", method: "POST", body: req)
        return r.data
    }

    func lockLocation(pharmacyId: String, lat: Double, lng: Double) async throws -> Pharmacy {
        let r: PharmacyResponse = try await request(path: "rep/pharmacies/\(pharmacyId)/lock-location", method: "POST", body: LockLocationRequest(lat: lat, lng: lng))
        return r.data
    }

    func checkin(pharmacyId: String, lat: Double, lng: Double) async throws {
        let _: EmptyResponse = try await request(path: "rep/visits/checkin", method: "POST", body: CheckinRequest(pharmacyId: pharmacyId, lat: lat, lng: lng))
    }

    func listSuppliers() async throws -> [Supplier] {
        let r: SupplierList = try await get("rep/suppliers")
        return r.data
    }

    func getSupplierInvoices(supplierId: String) async throws -> SupplierInvoicesResponse {
        try await get("rep/suppliers/\(supplierId)/invoices")
    }

    func listPaymentPlans(paidOnly: Bool = false) async throws -> [PaymentPlan] {
        var path = "rep/supplier-payment-plans"
        if paidOnly { path += "?paid_only=1" }
        let r: PaymentPlanList = try await get(path)
        return r.data
    }

    func getPaymentPlan(id: String) async throws -> PaymentPlanDetail {
        let r: PaymentPlanDetailResponse = try await get("rep/supplier-payment-plans/\(id)")
        return r.data
    }

    func createPaymentPlan(_ req: CreatePaymentPlanRequest) async throws {
        let _: PaymentPlanDetailResponse = try await request(path: "rep/supplier-payment-plans", method: "POST", body: req)
    }

    func deletePaymentPlan(id: String) async throws {
        let _: EmptyResponse = try await request(path: "rep/supplier-payment-plans/\(id)", method: "DELETE", body: Optional<String>.none as String?)
    }

    func payInstallment(id: String, paid: Double, discount: Double) async throws {
        let _: EmptyResponse = try await request(path: "rep/supplier-payment-installments/\(id)/pay", method: "POST", body: PayInstallmentRequest(paidAmount: paid, discountAmount: discount))
    }

    func updateInstallmentPayment(id: String, paid: Double, discount: Double) async throws {
        let _: EmptyResponse = try await request(path: "rep/supplier-payment-installments/\(id)", method: "PATCH", body: UpdateInstallmentPaymentRequest(paidAmount: paid, discountAmount: discount))
    }

    func cancelInstallmentPayment(id: String) async throws {
        let _: EmptyResponse = try await request(path: "rep/supplier-payment-installments/\(id)/cancel-payment", method: "POST", body: Optional<String>.none as String?)
    }

    func cancelAppointment(id: String) async throws {
        let _: EmptyResponse = try await request(path: "rep/supplier-payment-installments/\(id)/cancel-appointment", method: "POST", body: Optional<String>.none as String?)
    }

    func getReminders() async throws -> RemindersResponse {
        try await get("rep/reminders")
    }

    // MARK: - Driver

    func listOrdersToday() async throws -> [DeliveryOrder] {
        let r: OrderList = try await get("driver/orders/today")
        return r.data
    }

    func getOrder(id: String) async throws -> DeliveryOrder {
        let r: OrderResponse = try await get("driver/orders/\(id)")
        return r.data
    }

    func startOrder(id: String) async throws -> DeliveryOrder {
        let r: OrderResponse = try await request(path: "driver/orders/\(id)/start", method: "POST", body: Optional<String>.none as String?)
        return r.data
    }

    // MARK: - HTTP core

    private struct EmptyResponse: Decodable {}

    private func get<T: Decodable>(_ path: String) async throws -> T {
        try await request(path: path, method: "GET", body: Optional<String>.none as String?)
    }

    private func request<T: Decodable, B: Encodable>(
        path: String,
        method: String,
        body: B?,
        auth: Bool = true
    ) async throws -> T {
        let url = APIClient.baseURL.appendingPathComponent(path)
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try encoder.encode(body)
        }
        if auth, let token = tokenStore.token {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidURL }

        if http.statusCode == 401, auth, !path.contains("auth/login"), !path.contains("auth/refresh") {
            if let newToken = await refreshAccessToken() {
                var retry = req
                retry.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
                let (d2, r2) = try await session.data(for: retry)
                guard let h2 = r2 as? HTTPURLResponse else { throw APIError.invalidURL }
                return try decodeResponse(data: d2, status: h2.statusCode)
            }
            tokenStore.clear()
            throw APIError.unauthorized
        }

        return try decodeResponse(data: data, status: http.statusCode)
    }

    private func decodeResponse<T: Decodable>(data: Data, status: Int) throws -> T {
        if status >= 400 {
            let msg = (try? decoder.decode(APIErrorBody.self, from: data))?.message
                ?? (try? decoder.decode(APIErrorBody.self, from: data))?.error
            throw APIError.http(status, msg)
        }
        if T.self == EmptyResponse.self {
            return EmptyResponse() as! T
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }

    private func refreshAccessToken() async -> String? {
        if let task = refreshTask { return await task.value }
        let task = Task<String?, Never> {
            defer { refreshTask = nil }
            guard let refresh = tokenStore.refreshTokenValue() else { return nil }
            do {
                let url = APIClient.baseURL.appendingPathComponent("auth/refresh")
                var req = URLRequest(url: url)
                req.httpMethod = "POST"
                req.setValue("application/json", forHTTPHeaderField: "Content-Type")
                req.httpBody = try encoder.encode(RefreshRequest(refreshToken: refresh))
                let (data, response) = try await session.data(for: req)
                guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
                let res = try decoder.decode(RefreshResponse.self, from: data)
                tokenStore.updateAccessToken(res.token)
                return res.token
            } catch {
                return nil
            }
        }
        refreshTask = task
        return await task.value
    }
}
