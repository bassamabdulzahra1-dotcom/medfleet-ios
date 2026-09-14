import Foundation

// MARK: - Flexible numeric decoding
// Postgres returns NUMERIC columns (qty_on_hand, sale_price, standard_cost, ...) as strings.
// This helper decodes a Double whether the JSON value is a number or a numeric string.
extension KeyedDecodingContainer {
    func flexibleDouble(_ key: Key) -> Double? {
        if let d = try? decode(Double.self, forKey: key) { return d }
        if let s = try? decode(String.self, forKey: key) { return Double(s) }
        return nil
    }
}

// MARK: - Inventory (المخزن)

struct InventoryItem: Identifiable, Decodable {
    let id: String
    let name: String
    let scientificName: String?
    let category: String?
    let qtyOnHand: Double?
    let salePrice: Double?
    let standardCost: Double?
    let barcode: String?
    let stripsPerPacket: Int?
    let batchNumber: String?
    let expiryDate: String?

    enum CodingKeys: String, CodingKey {
        case id, name, category, barcode
        case scientificName = "scientific_name"
        case qtyOnHand = "qty_on_hand"
        case salePrice = "sale_price"
        case standardCost = "standard_cost"
        case stripsPerPacket = "strips_per_packet"
        case batchNumber = "batch_number"
        case expiryDate = "expiry_date"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = (try? c.decode(String.self, forKey: .name)) ?? ""
        scientificName = try? c.decodeIfPresent(String.self, forKey: .scientificName)
        category = try? c.decodeIfPresent(String.self, forKey: .category)
        qtyOnHand = c.flexibleDouble(.qtyOnHand)
        salePrice = c.flexibleDouble(.salePrice)
        standardCost = c.flexibleDouble(.standardCost)
        barcode = try? c.decodeIfPresent(String.self, forKey: .barcode)
        stripsPerPacket = try? c.decodeIfPresent(Int.self, forKey: .stripsPerPacket)
        batchNumber = try? c.decodeIfPresent(String.self, forKey: .batchNumber)
        expiryDate = try? c.decodeIfPresent(String.self, forKey: .expiryDate)
    }
}

struct InventoryListResponse: Decodable { let data: [InventoryItem] }

// MARK: - Scan orders (مسوّدات المسح)

struct BuyerScanOrder: Identifiable, Decodable {
    let id: String
    let ref: String?
    let status: String?
    let vendorRef: String?
    let amountTotal: String?
    let supplierName: String?
    let scanImageUrl: String?
    let lineCount: Int?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, ref, status
        case vendorRef = "vendor_ref"
        case amountTotal = "amount_total"
        case supplierName = "supplier_name"
        case scanImageUrl = "scan_image_url"
        case lineCount = "line_count"
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        ref = try? c.decodeIfPresent(String.self, forKey: .ref)
        status = try? c.decodeIfPresent(String.self, forKey: .status)
        vendorRef = try? c.decodeIfPresent(String.self, forKey: .vendorRef)
        // amount_total قد يرجع رقم أو نص — نخزنه كنص للعرض
        if let s = try? c.decodeIfPresent(String.self, forKey: .amountTotal) {
            amountTotal = s
        } else if let d = c.flexibleDouble(.amountTotal) {
            amountTotal = String(d)
        } else {
            amountTotal = nil
        }
        supplierName = try? c.decodeIfPresent(String.self, forKey: .supplierName)
        scanImageUrl = try? c.decodeIfPresent(String.self, forKey: .scanImageUrl)
        lineCount = try? c.decodeIfPresent(Int.self, forKey: .lineCount)
        createdAt = try? c.decodeIfPresent(String.self, forKey: .createdAt)
    }
}

struct BuyerScanListResponse: Decodable { let data: [BuyerScanOrder] }

// سطر ضمن نتيجة المسح/المعاينة (القيم الرقمية ترجع كنصوص)
struct BuyerScanLine: Decodable {
    let id: String?
    let productName: String
    let productCategory: String?
    let qty: String?
    let unitPrice: String?
    let discountPercent: String?
    let subtotal: String?
    let batchNumber: String?
    let expiryDate: String?
    let matched: Bool
    let inStock: String?
    let salePrice: String?
    let inventoryProductId: String?

    enum CodingKeys: String, CodingKey {
        case id, qty, subtotal, matched
        case productName = "product_name"
        case productCategory = "product_category"
        case unitPrice = "unit_price"
        case discountPercent = "discount_percent"
        case batchNumber = "batch_number"
        case expiryDate = "expiry_date"
        case inStock = "in_stock"
        case salePrice = "sale_price"
        case inventoryProductId = "inventory_product_id"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try? c.decodeIfPresent(String.self, forKey: .id)
        productName = (try? c.decode(String.self, forKey: .productName)) ?? ""
        productCategory = try? c.decodeIfPresent(String.self, forKey: .productCategory)
        qty = try? c.decodeIfPresent(String.self, forKey: .qty)
        unitPrice = try? c.decodeIfPresent(String.self, forKey: .unitPrice)
        discountPercent = try? c.decodeIfPresent(String.self, forKey: .discountPercent)
        subtotal = try? c.decodeIfPresent(String.self, forKey: .subtotal)
        batchNumber = try? c.decodeIfPresent(String.self, forKey: .batchNumber)
        expiryDate = try? c.decodeIfPresent(String.self, forKey: .expiryDate)
        matched = (try? c.decode(Bool.self, forKey: .matched)) ?? false
        inStock = try? c.decodeIfPresent(String.self, forKey: .inStock)
        salePrice = try? c.decodeIfPresent(String.self, forKey: .salePrice)
        inventoryProductId = try? c.decodeIfPresent(String.self, forKey: .inventoryProductId)
    }
}

// سطر مستخرَج من الذكاء الاصطناعي (يُعاد إرساله عند الاعتماد)
struct BuyerExtractLine: Codable {
    let productName: String?
    let productCategory: String?
    let qty: Double
    let unitPrice: Double
    let discountPercent: Double
    let batchNumber: String?
    let expiryDate: String?

    enum CodingKeys: String, CodingKey {
        case qty
        case productName = "product_name"
        case productCategory = "product_category"
        case unitPrice = "unit_price"
        case discountPercent = "discount_percent"
        case batchNumber = "batch_number"
        case expiryDate = "expiry_date"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        productName = try? c.decodeIfPresent(String.self, forKey: .productName)
        productCategory = try? c.decodeIfPresent(String.self, forKey: .productCategory)
        qty = c.flexibleDouble(.qty) ?? 0
        unitPrice = c.flexibleDouble(.unitPrice) ?? 0
        discountPercent = c.flexibleDouble(.discountPercent) ?? 0
        batchNumber = try? c.decodeIfPresent(String.self, forKey: .batchNumber)
        expiryDate = try? c.decodeIfPresent(String.self, forKey: .expiryDate)
    }
}

struct BuyerExtractedFull: Codable {
    let supplierName: String?
    let vendorRef: String?
    let invoiceDate: String?
    let currency: String?
    let provider: String?
    let lines: [BuyerExtractLine]

    enum CodingKeys: String, CodingKey {
        case currency, provider, lines
        case supplierName = "supplier_name"
        case vendorRef = "vendor_ref"
        case invoiceDate = "invoice_date"
    }
}

// نتيجة المعاينة (قبل الاعتماد)
struct BuyerPreviewData: Decodable {
    let imageUrl: String?
    let extracted: BuyerExtractedFull
    let lines: [BuyerScanLine]
    let supplierName: String?
    let vendorRef: String?
    let invoiceDate: String?
    let amountTotal: String?
    let provider: String?

    enum CodingKeys: String, CodingKey {
        case extracted, lines, provider
        case imageUrl = "image_url"
        case supplierName = "supplier_name"
        case vendorRef = "vendor_ref"
        case invoiceDate = "invoice_date"
        case amountTotal = "amount_total"
    }
}

struct BuyerPreviewResponse: Decodable { let data: BuyerPreviewData }

// نتيجة الاعتماد (المسوّدة المُنشأة)
struct BuyerScanData: Decodable {
    let order: BuyerScanOrder
    let lines: [BuyerScanLine]
    let extracted: BuyerExtractedFull?
    let provider: String?
}

struct BuyerScanResponse: Decodable { let data: BuyerScanData }

// جسم طلب الاعتماد
struct BuyerCommitRequest: Encodable {
    let imageUrl: String?
    let extracted: BuyerExtractedFull

    enum CodingKeys: String, CodingKey {
        case extracted
        case imageUrl = "image_url"
    }
}

// MARK: - Inventory audit (الجرد المخزني)

struct BuyerInventoryAuditLineInput: Encodable {
    let productId: String
    let productName: String
    let barcode: String?
    let stockQty: Double
    let currentQty: Double
    let diffQty: Double
    let unitCost: Double
    let diffValue: Double
    let batchNumber: String?
    let expiryDate: String?

    enum CodingKeys: String, CodingKey {
        case barcode
        case productId = "product_id"
        case productName = "product_name"
        case stockQty = "stock_qty"
        case currentQty = "current_qty"
        case diffQty = "diff_qty"
        case unitCost = "unit_cost"
        case diffValue = "diff_value"
        case batchNumber = "batch_number"
        case expiryDate = "expiry_date"
    }
}

struct BuyerInventoryAuditCommitRequest: Encodable {
    let lines: [BuyerInventoryAuditLineInput]
    let note: String?
    let totalDiffValue: Double

    enum CodingKeys: String, CodingKey {
        case lines, note
        case totalDiffValue = "total_diff_value"
    }
}

struct BuyerInventoryAuditCommitResult: Decodable {
    let reference: String?
    let message: String?
    let totalDiffValue: Double?

    enum CodingKeys: String, CodingKey {
        case reference, message
        case totalDiffValue = "total_diff_value"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        reference = try? c.decodeIfPresent(String.self, forKey: .reference)
        message = try? c.decodeIfPresent(String.self, forKey: .message)
        totalDiffValue = c.flexibleDouble(.totalDiffValue)
    }
}

struct BuyerInventoryAuditCommitResponse: Decodable {
    let data: BuyerInventoryAuditCommitResult

    private enum RootKeys: String, CodingKey {
        case data, message, reference
        case totalDiffValue = "total_diff_value"
    }

    init(from decoder: Decoder) throws {
        let root = try decoder.container(keyedBy: RootKeys.self)
        if let nested = try? root.decode(BuyerInventoryAuditCommitResult.self, forKey: .data) {
            data = nested
            return
        }
        data = BuyerInventoryAuditCommitResult(
            reference: try? root.decodeIfPresent(String.self, forKey: .reference),
            message: try? root.decodeIfPresent(String.self, forKey: .message),
            totalDiffValue: root.flexibleDouble(.totalDiffValue)
        )
    }
}

private extension BuyerInventoryAuditCommitResult {
    init(reference: String?, message: String?, totalDiffValue: Double?) {
        self.reference = reference
        self.message = message
        self.totalDiffValue = totalDiffValue
    }
}

// MARK: - POS sessions (تقارير جلسات نقطة البيع)

struct PosSessionInvoiceLine: Identifiable, Decodable {
    var id: String { "\(productName)-\(qty)-\(subtotal)" }
    let productName: String
    let qty: Double
    let unitPrice: Double
    let subtotal: Double

    enum CodingKeys: String, CodingKey {
        case qty
        case productName = "product_name"
        case unitPrice = "unit_price"
        case subtotal
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        productName = (try? c.decodeIfPresent(String.self, forKey: .productName)) ?? "—"
        qty = c.flexibleDouble(.qty) ?? 0
        unitPrice = c.flexibleDouble(.unitPrice) ?? 0
        subtotal = c.flexibleDouble(.subtotal) ?? 0
    }
}

struct PosSessionInvoice: Identifiable, Decodable {
    let id: String
    let ref: String?
    let createdAt: String?
    let amountTotal: Double
    let customerName: String?
    let lines: [PosSessionInvoiceLine]

    enum CodingKeys: String, CodingKey {
        case id, ref, lines
        case createdAt = "created_at"
        case amountTotal = "amount_total"
        case customerName = "customer_name"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        ref = try? c.decodeIfPresent(String.self, forKey: .ref)
        createdAt = try? c.decodeIfPresent(String.self, forKey: .createdAt)
        amountTotal = c.flexibleDouble(.amountTotal) ?? 0
        customerName = try? c.decodeIfPresent(String.self, forKey: .customerName)
        lines = (try? c.decodeIfPresent([PosSessionInvoiceLine].self, forKey: .lines)) ?? []
    }
}

struct PosSession: Identifiable, Decodable, Hashable {
    let id: String
    let openedBy: String?
    let closedBy: String?
    let openedAt: String?
    let closedAt: String?
    let invoiceCount: Int
    let posSalesTotal: Double
    let outsideSales: Double
    let totalSales: Double
    let isOpen: Bool
    let invoices: [PosSessionInvoice]

    enum CodingKeys: String, CodingKey {
        case id, invoices
        case openedBy = "opened_by"
        case closedBy = "closed_by"
        case openedAt = "opened_at"
        case closedAt = "closed_at"
        case invoiceCount = "invoice_count"
        case posSalesTotal = "pos_sales_total"
        case outsideSales = "outside_sales"
        case totalSales = "total_sales"
        case isOpen = "is_open"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        openedBy = try? c.decodeIfPresent(String.self, forKey: .openedBy)
        closedBy = try? c.decodeIfPresent(String.self, forKey: .closedBy)
        openedAt = try? c.decodeIfPresent(String.self, forKey: .openedAt)
        closedAt = try? c.decodeIfPresent(String.self, forKey: .closedAt)
        invoiceCount = (try? c.decodeIfPresent(Int.self, forKey: .invoiceCount)) ?? 0
        posSalesTotal = c.flexibleDouble(.posSalesTotal) ?? 0
        outsideSales = c.flexibleDouble(.outsideSales) ?? 0
        totalSales = c.flexibleDouble(.totalSales) ?? 0
        isOpen = (try? c.decodeIfPresent(Bool.self, forKey: .isOpen)) ?? (closedAt == nil)
        invoices = (try? c.decodeIfPresent([PosSessionInvoice].self, forKey: .invoices)) ?? []
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: PosSession, rhs: PosSession) -> Bool { lhs.id == rhs.id }
}

struct PosSessionListResponse: Decodable { let data: [PosSession] }
struct PosSessionDetailResponse: Decodable { let data: PosSession }
struct PosSessionCurrentResponse: Decodable { let data: PosSession? }

struct PosSessionEvent: Decodable {
    let type: String
    let sessionId: String
    let cashier: String?
    let at: String?
    let amount: Double

    enum CodingKeys: String, CodingKey {
        case type, cashier, at, amount
        case sessionId = "session_id"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        type = (try? c.decodeIfPresent(String.self, forKey: .type)) ?? ""
        sessionId = (try? c.decodeIfPresent(String.self, forKey: .sessionId)) ?? ""
        cashier = try? c.decodeIfPresent(String.self, forKey: .cashier)
        at = try? c.decodeIfPresent(String.self, forKey: .at)
        amount = c.flexibleDouble(.amount) ?? 0
    }
}

struct PosSessionEventsResponse: Decodable {
    let data: [PosSessionEvent]
    let serverTime: String?

    enum CodingKeys: String, CodingKey {
        case data
        case serverTime = "server_time"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        data = (try? c.decodeIfPresent([PosSessionEvent].self, forKey: .data)) ?? []
        serverTime = try? c.decodeIfPresent(String.self, forKey: .serverTime)
    }
}

// MARK: - Purchase returns (مردود الشراء)

struct PurchaseReturnLineInput: Encodable {
    let barcode: String?
    let productName: String?
    let qty: Double

    enum CodingKeys: String, CodingKey {
        case barcode, qty
        case productName = "product_name"
    }
}

struct PurchaseReturnCreateRequest: Encodable {
    let vendorName: String
    let invoiceNo: String?
    let lines: [PurchaseReturnLineInput]

    enum CodingKeys: String, CodingKey {
        case lines
        case vendorName = "vendor_name"
        case invoiceNo = "invoice_no"
    }
}

struct PurchaseReturnLine: Identifiable, Decodable {
    let id: String?
    let productId: String?
    let productName: String
    let barcode: String?
    let qty: Double
    let unitPrice: Double
    let subtotal: Double

    enum CodingKeys: String, CodingKey {
        case id, barcode, qty, subtotal
        case productId = "product_id"
        case productName = "product_name"
        case unitPrice = "unit_price"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try? c.decodeIfPresent(String.self, forKey: .id)
        productId = try? c.decodeIfPresent(String.self, forKey: .productId)
        productName = (try? c.decodeIfPresent(String.self, forKey: .productName)) ?? ""
        barcode = try? c.decodeIfPresent(String.self, forKey: .barcode)
        qty = c.flexibleDouble(.qty) ?? 0
        unitPrice = c.flexibleDouble(.unitPrice) ?? 0
        subtotal = c.flexibleDouble(.subtotal) ?? 0
    }
}

struct PurchaseReturn: Identifiable, Decodable {
    let id: String
    let ref: String?
    let vendorName: String?
    let invoiceNo: String?
    let amountTotal: Double
    let status: String?
    let createdAt: String?
    let lines: [PurchaseReturnLine]

    enum CodingKeys: String, CodingKey {
        case id, ref, status, lines
        case vendorName = "vendor_name"
        case invoiceNo = "invoice_no"
        case amountTotal = "amount_total"
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        ref = try? c.decodeIfPresent(String.self, forKey: .ref)
        vendorName = try? c.decodeIfPresent(String.self, forKey: .vendorName)
        invoiceNo = try? c.decodeIfPresent(String.self, forKey: .invoiceNo)
        amountTotal = c.flexibleDouble(.amountTotal) ?? 0
        status = try? c.decodeIfPresent(String.self, forKey: .status)
        createdAt = try? c.decodeIfPresent(String.self, forKey: .createdAt)
        lines = (try? c.decodeIfPresent([PurchaseReturnLine].self, forKey: .lines)) ?? []
    }
}

struct PurchaseReturnListResponse: Decodable { let data: [PurchaseReturn] }
struct PurchaseReturnResponse: Decodable { let data: PurchaseReturn }

struct BuyerSupplierOffice: Identifiable, Decodable, Hashable {
    let id: String
    let name: String
}

struct BuyerSupplierListResponse: Decodable { let data: [BuyerSupplierOffice] }
