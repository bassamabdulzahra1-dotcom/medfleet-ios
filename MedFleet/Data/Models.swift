import Foundation

struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct LoginResponse: Decodable {
    let token: String
    let refreshToken: String?
    let user: User

    enum CodingKeys: String, CodingKey {
        case token
        case refreshToken = "refresh_token"
        case user
    }
}

struct RefreshRequest: Encodable {
    let refreshToken: String
    enum CodingKeys: String, CodingKey { case refreshToken = "refresh_token" }
}

struct RefreshResponse: Decodable { let token: String }

struct User: Codable, Equatable {
    let id: String
    let email: String
    let name: String
    let role: String
}

struct Pharmacy: Identifiable, Decodable {
    let id: String
    let name: String
    let address: String?
    let region: String?
    let contactPhone: String?
    let classification: String?
    let latitude: Double?
    let longitude: Double?
    let geofenceM: Int?
    let locationLocked: Bool?

    enum CodingKeys: String, CodingKey {
        case id, name, address, region, classification, latitude, longitude
        case contactPhone = "contact_phone"
        case geofenceM = "geofence_m"
        case locationLocked = "location_locked"
    }
}

struct PharmacyList: Decodable { let data: [Pharmacy] }
struct PharmacyResponse: Decodable { let data: Pharmacy }

struct PharmacyCreateRequest: Encodable {
    let name: String
    let address: String?
    let region: String?
    let contactPhone: String?
    let classification: String
    let latitude: Double?
    let longitude: Double?
    let geofenceM: Int
    enum CodingKeys: String, CodingKey {
        case name, address, region, classification, latitude, longitude
        case contactPhone = "contact_phone"
        case geofenceM = "geofence_m"
    }
}

struct LockLocationRequest: Encodable { let lat: Double; let lng: Double }
struct CheckinRequest: Encodable {
    let pharmacyId: String
    let lat: Double
    let lng: Double
    enum CodingKeys: String, CodingKey {
        case lat, lng
        case pharmacyId = "pharmacy_id"
    }
}

struct Supplier: Identifiable, Codable {
    let id: String
    let name: String
    let debtBalance: Double
    let lastPurchaseAt: String?
    let scheduledRemaining: Double?

    enum CodingKeys: String, CodingKey {
        case id, name
        case debtBalance = "debt_balance"
        case lastPurchaseAt = "last_purchase_at"
        case scheduledRemaining = "scheduled_remaining"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeFlexibleString(forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        debtBalance = try c.decodeFlexibleDouble(forKey: .debtBalance)
        lastPurchaseAt = try c.decodeIfPresent(String.self, forKey: .lastPurchaseAt)
        scheduledRemaining = try c.decodeFlexibleDoubleIfPresent(forKey: .scheduledRemaining)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(debtBalance, forKey: .debtBalance)
        try c.encodeIfPresent(lastPurchaseAt, forKey: .lastPurchaseAt)
        try c.encodeIfPresent(scheduledRemaining, forKey: .scheduledRemaining)
    }
}

struct SupplierList: Decodable { let data: [Supplier] }

struct SupplierInvoice: Identifiable, Decodable {
    let id: String
    let name: String?
    let ref: String?
    let invoiceDate: String?
    let invoiceDateDue: String?
    let amountTotal: Double
    let amountResidual: Double
    let paymentState: String?
    let currency: String?

    enum CodingKeys: String, CodingKey {
        case id, name, ref, currency
        case invoiceDate = "invoice_date"
        case invoiceDateDue = "invoice_date_due"
        case amountTotal = "amount_total"
        case amountResidual = "amount_residual"
        case paymentState = "payment_state"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeFlexibleString(forKey: .id)
        name = try c.decodeIfPresent(String.self, forKey: .name)
        ref = try c.decodeFlexibleStringIfPresent(forKey: .ref)
        invoiceDate = try c.decodeIfPresent(String.self, forKey: .invoiceDate)
        invoiceDateDue = try c.decodeIfPresent(String.self, forKey: .invoiceDateDue)
        amountTotal = try c.decodeFlexibleDouble(forKey: .amountTotal)
        amountResidual = try c.decodeFlexibleDouble(forKey: .amountResidual)
        paymentState = try c.decodeIfPresent(String.self, forKey: .paymentState)
        currency = try c.decodeIfPresent(String.self, forKey: .currency)
    }
}

struct SupplierInvoicesResponse: Decodable {
    let data: [SupplierInvoice]
    let totalResidual: Double
    let noOdooRef: Bool

    enum CodingKeys: String, CodingKey {
        case data
        case totalResidual = "total_residual"
        case noOdooRef = "no_odoo_ref"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        data = try c.decodeIfPresent([SupplierInvoice].self, forKey: .data) ?? []
        totalResidual = try c.decodeFlexibleDoubleIfPresent(forKey: .totalResidual) ?? 0
        noOdooRef = (try? c.decode(Bool.self, forKey: .noOdooRef)) ?? false
    }
}

struct SupplierInvoiceLine: Identifiable, Decodable {
    let id: String
    let productId: String?
    let name: String?
    let defaultCode: String?
    let quantity: Double
    let priceUnit: Double
    let priceSubtotal: Double
    let uom: String?
    let stockQty: Double?
    let freeQty: Double?

    enum CodingKeys: String, CodingKey {
        case id, name, quantity, uom
        case productId = "product_id"
        case defaultCode = "default_code"
        case priceUnit = "price_unit"
        case priceSubtotal = "price_subtotal"
        case stockQty = "stock_qty"
        case freeQty = "free_qty"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeFlexibleString(forKey: .id)
        productId = try c.decodeFlexibleStringIfPresent(forKey: .productId)
        name = try c.decodeIfPresent(String.self, forKey: .name)
        defaultCode = try c.decodeIfPresent(String.self, forKey: .defaultCode)
        quantity = try c.decodeFlexibleDouble(forKey: .quantity)
        priceUnit = try c.decodeFlexibleDouble(forKey: .priceUnit)
        priceSubtotal = try c.decodeFlexibleDouble(forKey: .priceSubtotal)
        uom = try c.decodeIfPresent(String.self, forKey: .uom)
        stockQty = try c.decodeFlexibleDoubleIfPresent(forKey: .stockQty)
        freeQty = try c.decodeFlexibleDoubleIfPresent(forKey: .freeQty)
    }
}

struct InvoiceLinesResponse: Decodable {
    let data: [SupplierInvoiceLine]
    let invoiceName: String?

    enum CodingKeys: String, CodingKey {
        case data
        case invoiceName = "invoice_name"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        data = try c.decodeIfPresent([SupplierInvoiceLine].self, forKey: .data) ?? []
        invoiceName = try c.decodeIfPresent(String.self, forKey: .invoiceName)
    }
}

struct PlanInvoice: Encodable {
    let id: Int
    let name: String?
    let invoiceDate: String?
    let amountResidual: Double
    enum CodingKeys: String, CodingKey {
        case id, name
        case invoiceDate = "invoice_date"
        case amountResidual = "amount_residual"
    }
}

struct InstallmentInput: Encodable {
    let dueDate: String
    let amount: Double
    enum CodingKeys: String, CodingKey { case dueDate = "due_date"; case amount }
}

struct CreatePaymentPlanRequest: Encodable {
    let supplierId: String
    let plannedAmount: Double
    let discountAmount: Double
    let notes: String?
    let installments: [InstallmentInput]
    let invoices: [PlanInvoice]?
    enum CodingKeys: String, CodingKey {
        case notes, installments, invoices
        case supplierId = "supplier_id"
        case plannedAmount = "planned_amount"
        case discountAmount = "discount_amount"
    }
}

struct PaymentPlan: Identifiable, Codable {
    let id: String
    let supplierId: String
    let supplierName: String?
    let plannedAmount: Double
    let discountAmount: Double
    let netAmount: Double
    let status: String
    let paidCount: Int?
    let installmentCount: Int?
    let paidTotal: Double?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, status
        case supplierId = "supplier_id"
        case supplierName = "supplier_name"
        case plannedAmount = "planned_amount"
        case discountAmount = "discount_amount"
        case netAmount = "net_amount"
        case paidCount = "paid_count"
        case installmentCount = "installment_count"
        case paidTotal = "paid_total"
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeFlexibleString(forKey: .id)
        supplierId = try c.decodeFlexibleString(forKey: .supplierId)
        supplierName = try c.decodeIfPresent(String.self, forKey: .supplierName)
        plannedAmount = try c.decodeFlexibleDouble(forKey: .plannedAmount)
        discountAmount = try c.decodeFlexibleDouble(forKey: .discountAmount)
        netAmount = try c.decodeFlexibleDouble(forKey: .netAmount)
        status = try c.decode(String.self, forKey: .status)
        paidCount = try c.decodeIfPresent(Int.self, forKey: .paidCount)
        installmentCount = try c.decodeIfPresent(Int.self, forKey: .installmentCount)
        paidTotal = try c.decodeFlexibleDoubleIfPresent(forKey: .paidTotal)
        createdAt = try c.decodeIfPresent(String.self, forKey: .createdAt)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(supplierId, forKey: .supplierId)
        try c.encodeIfPresent(supplierName, forKey: .supplierName)
        try c.encode(plannedAmount, forKey: .plannedAmount)
        try c.encode(discountAmount, forKey: .discountAmount)
        try c.encode(netAmount, forKey: .netAmount)
        try c.encode(status, forKey: .status)
        try c.encodeIfPresent(paidCount, forKey: .paidCount)
        try c.encodeIfPresent(installmentCount, forKey: .installmentCount)
        try c.encodeIfPresent(paidTotal, forKey: .paidTotal)
        try c.encodeIfPresent(createdAt, forKey: .createdAt)
    }
}

struct PaymentPlanList: Decodable { let data: [PaymentPlan] }

struct PaymentInstallment: Identifiable, Decodable {
    let id: String
    let seqNo: Int
    let dueDate: String
    let amount: Double
    let discountAmount: Double
    let paidAmount: Double
    let status: String
    let paidAt: String?

    enum CodingKeys: String, CodingKey {
        case id, amount, status
        case seqNo = "seq_no"
        case dueDate = "due_date"
        case discountAmount = "discount_amount"
        case paidAmount = "paid_amount"
        case paidAt = "paid_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeFlexibleString(forKey: .id)
        seqNo = try c.decode(Int.self, forKey: .seqNo)
        dueDate = try c.decode(String.self, forKey: .dueDate)
        amount = try c.decodeFlexibleDouble(forKey: .amount)
        discountAmount = try c.decodeFlexibleDouble(forKey: .discountAmount)
        paidAmount = try c.decodeFlexibleDouble(forKey: .paidAmount)
        status = try c.decode(String.self, forKey: .status)
        paidAt = try c.decodeIfPresent(String.self, forKey: .paidAt)
    }
}

struct PaymentPlanDetail: Decodable {
    let plan: PaymentPlan
    let installments: [PaymentInstallment]
}

struct PaymentPlanDetailResponse: Decodable { let data: PaymentPlanDetail }

struct PayInstallmentRequest: Encodable {
    let paidAmount: Double
    let discountAmount: Double
    enum CodingKeys: String, CodingKey {
        case paidAmount = "paid_amount"
        case discountAmount = "discount_amount"
    }
}

struct UpdateInstallmentPaymentRequest: Encodable {
    let paidAmount: Double
    let discountAmount: Double
    enum CodingKeys: String, CodingKey {
        case paidAmount = "paid_amount"
        case discountAmount = "discount_amount"
    }
}

struct Reminder: Identifiable, Codable {
    let id: String
    let type: String?
    let dueDate: String
    let amount: Double
    let supplierName: String?
    let planId: String?
    let title: String?
    let isOverdue: Bool?

    enum CodingKeys: String, CodingKey {
        case id, type, amount, title
        case dueDate = "due_date"
        case supplierName = "supplier_name"
        case planId = "plan_id"
        case isOverdue = "is_overdue"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeFlexibleString(forKey: .id)
        type = try c.decodeIfPresent(String.self, forKey: .type)
        dueDate = try c.decode(String.self, forKey: .dueDate)
        amount = try c.decodeFlexibleDouble(forKey: .amount)
        supplierName = try c.decodeIfPresent(String.self, forKey: .supplierName)
        planId = try c.decodeFlexibleStringIfPresent(forKey: .planId)
        title = try c.decodeIfPresent(String.self, forKey: .title)
        isOverdue = try c.decodeIfPresent(Bool.self, forKey: .isOverdue)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encodeIfPresent(type, forKey: .type)
        try c.encode(dueDate, forKey: .dueDate)
        try c.encode(amount, forKey: .amount)
        try c.encodeIfPresent(supplierName, forKey: .supplierName)
        try c.encodeIfPresent(planId, forKey: .planId)
        try c.encodeIfPresent(title, forKey: .title)
        try c.encodeIfPresent(isOverdue, forKey: .isOverdue)
    }
}

struct RemindersResponse: Decodable {
    let data: [Reminder]
    let count: Int?
    let totalAmount: Double?
    enum CodingKeys: String, CodingKey {
        case data, count
        case totalAmount = "total_amount"
    }
}

// MARK: - Supplier settlements (payments ledger)

struct Settlement: Identifiable, Decodable {
    let id: String
    let amount: Double
    let settledAt: String
    let supplierId: String
    let supplierName: String?
    let day: String?

    enum CodingKeys: String, CodingKey {
        case id, amount, day
        case settledAt = "settled_at"
        case supplierId = "supplier_id"
        case supplierName = "supplier_name"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeFlexibleString(forKey: .id)
        amount = try c.decodeFlexibleDouble(forKey: .amount)
        settledAt = try c.decode(String.self, forKey: .settledAt)
        supplierId = try c.decodeFlexibleString(forKey: .supplierId)
        supplierName = try c.decodeIfPresent(String.self, forKey: .supplierName)
        day = try c.decodeIfPresent(String.self, forKey: .day)
    }
}

struct SettlementDaily: Identifiable, Decodable {
    var id: String { day }
    let day: String
    let count: Int
    let total: Double

    enum CodingKeys: String, CodingKey { case day, count, total }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        day = try c.decode(String.self, forKey: .day)
        count = try c.decode(Int.self, forKey: .count)
        total = try c.decodeFlexibleDouble(forKey: .total)
    }
}

struct SettlementMonthly: Identifiable, Decodable {
    var id: String { month }
    let month: String
    let count: Int
    let total: Double

    enum CodingKeys: String, CodingKey { case month, count, total }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        month = try c.decode(String.self, forKey: .month)
        count = try c.decode(Int.self, forKey: .count)
        total = try c.decodeFlexibleDouble(forKey: .total)
    }
}

struct SettlementBySupplier: Identifiable, Decodable {
    var id: String { supplierId }
    let supplierId: String
    let supplierName: String?
    let count: Int
    let total: Double
    let lastSettledAt: String?

    enum CodingKeys: String, CodingKey {
        case count, total
        case supplierId = "supplier_id"
        case supplierName = "supplier_name"
        case lastSettledAt = "last_settled_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        supplierId = try c.decodeFlexibleString(forKey: .supplierId)
        supplierName = try c.decodeIfPresent(String.self, forKey: .supplierName)
        count = try c.decode(Int.self, forKey: .count)
        total = try c.decodeFlexibleDouble(forKey: .total)
        lastSettledAt = try c.decodeIfPresent(String.self, forKey: .lastSettledAt)
    }
}

struct SettlementsSummary: Decodable {
    let transactions: [Settlement]
    let daily: [SettlementDaily]
    let monthly: [SettlementMonthly]
    let bySupplier: [SettlementBySupplier]
    let grandTotal: Double
    let grandCount: Int

    enum CodingKeys: String, CodingKey {
        case transactions, daily, monthly
        case bySupplier = "by_supplier"
        case grandTotal = "grand_total"
        case grandCount = "grand_count"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        transactions = try c.decode([Settlement].self, forKey: .transactions)
        daily = try c.decode([SettlementDaily].self, forKey: .daily)
        monthly = try c.decode([SettlementMonthly].self, forKey: .monthly)
        bySupplier = try c.decode([SettlementBySupplier].self, forKey: .bySupplier)
        grandTotal = try c.decodeFlexibleDouble(forKey: .grandTotal)
        grandCount = try c.decode(Int.self, forKey: .grandCount)
    }
}

struct SettlementsResponse: Decodable { let data: SettlementsSummary }

struct ScanPreviewRequest: Encodable { let qrData: String; enum CodingKeys: String, CodingKey { case qrData = "qr_data" } }
struct ScanInvoiceRequest: Encodable {
    let qrData: String
    let lat: String?
    let lng: String?
    let note: String?
    enum CodingKeys: String, CodingKey { case qrData = "qr_data"; case lat, lng, note }
}

struct APIErrorBody: Decodable { let error: String?; let message: String? }

// MARK: - Flexible JSON numbers

private extension KeyedDecodingContainer {
    func decodeFlexibleDouble(forKey key: Key) throws -> Double {
        if let v = try? decode(Double.self, forKey: key) { return v }
        if let s = try? decode(String.self, forKey: key) {
            return Double(s.replacingOccurrences(of: ",", with: "")) ?? 0
        }
        return 0
    }

    func decodeFlexibleDoubleIfPresent(forKey key: Key) throws -> Double? {
        if (try? decodeNil(forKey: key)) == true { return nil }
        return try decodeFlexibleDouble(forKey: key)
    }

    /// Accepts the value as String, Int, or Double (backend may send numeric ids).
    func decodeFlexibleString(forKey key: Key) throws -> String {
        if let s = try? decode(String.self, forKey: key) { return s }
        if let i = try? decode(Int.self, forKey: key) { return String(i) }
        if let d = try? decode(Double.self, forKey: key) {
            return d == d.rounded() ? String(Int(d)) : String(d)
        }
        return try decode(String.self, forKey: key)
    }

    func decodeFlexibleStringIfPresent(forKey key: Key) throws -> String? {
        if (try? decodeNil(forKey: key)) == true { return nil }
        guard contains(key) else { return nil }
        return try? decodeFlexibleString(forKey: key)
    }
}
