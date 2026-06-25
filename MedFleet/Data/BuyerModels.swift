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

    enum CodingKeys: String, CodingKey {
        case id, name, category, barcode
        case scientificName = "scientific_name"
        case qtyOnHand = "qty_on_hand"
        case salePrice = "sale_price"
        case standardCost = "standard_cost"
        case stripsPerPacket = "strips_per_packet"
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
    let qty: Double
    let unitPrice: Double
    let discountPercent: Double
    let batchNumber: String?
    let expiryDate: String?

    enum CodingKeys: String, CodingKey {
        case qty
        case productName = "product_name"
        case unitPrice = "unit_price"
        case discountPercent = "discount_percent"
        case batchNumber = "batch_number"
        case expiryDate = "expiry_date"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        productName = try? c.decodeIfPresent(String.self, forKey: .productName)
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
