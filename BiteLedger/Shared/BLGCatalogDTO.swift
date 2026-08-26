import Foundation

struct BLGFlexibleNumber: Decodable, Sendable {
    let value: Double?

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            value = nil
            return
        }
        if let number = try? container.decode(Double.self) {
            value = number
            return
        }
        if let number = try? container.decode(Int.self) {
            value = Double(number)
            return
        }
        if let text = try? container.decode(String.self) {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                value = nil
                return
            }
            value = Double(trimmed.replacingOccurrences(of: ",", with: "."))
            return
        }
        value = nil
    }
}

struct BLGNutrimentsDTO: Decodable, Sendable {
    let energyKcal100g: BLGFlexibleNumber?
    let energy100g: BLGFlexibleNumber?
    let proteins100g: BLGFlexibleNumber?
    let carbohydrates100g: BLGFlexibleNumber?
    let fat100g: BLGFlexibleNumber?

    enum CodingKeys: String, CodingKey {
        case energyKcal100g = "energy-kcal_100g"
        case energy100g = "energy_100g"
        case proteins100g = "proteins_100g"
        case carbohydrates100g = "carbohydrates_100g"
        case fat100g = "fat_100g"
    }
}

struct BLGProductDTO: Decodable, Sendable {
    let code: String?
    let productName: String?
    let genericName: String?
    let brands: String?
    let nutriments: BLGNutrimentsDTO?
    let imageSmallUrl: String?
    let imageUrl: String?
    let imageFrontSmallUrl: String?

    enum CodingKeys: String, CodingKey {
        case code
        case productName = "product_name"
        case genericName = "generic_name"
        case brands
        case nutriments
        case imageSmallUrl = "image_small_url"
        case imageUrl = "image_url"
        case imageFrontSmallUrl = "image_front_small_url"
    }

    func mapped(fallbackCode: String = "") -> BLGProduct? {
        let barcode = (code?.isEmpty == false ? code : nil) ?? (fallbackCode.isEmpty ? nil : fallbackCode)
        guard let barcode else { return nil }
        let resolvedName = [productName, genericName, brands]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }
        guard let resolvedName else { return nil }
        let kcal = BLGPortionMath.kcal100(
            energyKcal100g: nutriments?.energyKcal100g?.value,
            energyKj100g: nutriments?.energy100g?.value
        )
        return BLGProduct(
            barcode: barcode,
            name: resolvedName,
            brand: brands?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            kcal100: kcal,
            protein100: nutriments?.proteins100g?.value,
            carbs100: nutriments?.carbohydrates100g?.value,
            fat100: nutriments?.fat100g?.value,
            imageURL: imageSmallUrl ?? imageFrontSmallUrl ?? imageUrl,
            bundledAsset: nil,
            lastRefresh: Int(Date().timeIntervalSince1970)
        )
    }
}

struct BLGSearchDTO: Decodable, Sendable {
    let products: [BLGProductDTO]?
    let count: Int?
}

struct BLGProductResponseDTO: Decodable, Sendable {
    let status: Int?
    let code: String?
    let product: BLGProductDTO?
}
