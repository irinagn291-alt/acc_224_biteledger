import Foundation

enum BLGSlot: String, CaseIterable, Sendable, Hashable {
    case opening
    case midday
    case closing
    case pettyCash

    var label: String {
        switch self {
        case .opening: return "Opening Entry"
        case .midday: return "Midday Entry"
        case .closing: return "Closing Entry"
        case .pettyCash: return "Petty Cash"
        }
    }

    var assetName: String {
        switch self {
        case .opening: return "blg_SlotOpeningEntry"
        case .midday: return "blg_SlotMiddayEntry"
        case .closing: return "blg_SlotClosingEntry"
        case .pettyCash: return "blg_SlotPettyCash"
        }
    }

    var canPlan: Bool { self != .pettyCash }
}

struct BLGProduct: Sendable, Hashable, Identifiable {
    var id: String { barcode }
    let barcode: String
    let name: String
    let brand: String
    let kcal100: Double?
    let protein100: Double?
    let carbs100: Double?
    let fat100: Double?
    let imageURL: String?
    let bundledAsset: String?
    let lastRefresh: Int
}

struct BLGEntry: Sendable, Hashable, Identifiable {
    let id: String
    let barcode: String
    let productName: String
    let brand: String
    let grams: Double
    let slot: BLGSlot
    let dayKey: String
    let kcal100: Double?
    let protein100: Double?
    let carbs100: Double?
    let fat100: Double?
    let imageURL: String?
    let createdAt: Int

    var kcal: Double? { BLGPortionMath.portion(per100: kcal100, grams: grams) }
    var protein: Double? { BLGPortionMath.portion(per100: protein100, grams: grams) }
    var carbs: Double? { BLGPortionMath.portion(per100: carbs100, grams: grams) }
    var fat: Double? { BLGPortionMath.portion(per100: fat100, grams: grams) }
}

struct BLGTargets: Sendable, Hashable {
    var kcal: Double
    var protein: Double?
    var carbs: Double?
    var fat: Double?

    static let sensible = BLGTargets(kcal: 2200, protein: 120, carbs: 250, fat: 70)
}

struct BLGWishItem: Sendable, Hashable, Identifiable {
    var id: String { barcode }
    let barcode: String
    let productName: String
    let brand: String
    let kcal100: Double?
    let protein100: Double?
    let carbs100: Double?
    let fat100: Double?
    let imageURL: String?
    let bundledAsset: String?
    let addedAt: Int

    var asProduct: BLGProduct {
        BLGProduct(
            barcode: barcode,
            name: productName,
            brand: brand,
            kcal100: kcal100,
            protein100: protein100,
            carbs100: carbs100,
            fat100: fat100,
            imageURL: imageURL,
            bundledAsset: bundledAsset,
            lastRefresh: addedAt
        )
    }
}

struct BLGDaySnapshot: Sendable {
    let dayKey: String
    let entries: [BLGEntry]
    let targets: BLGTargets

    var energy: Double {
        entries.compactMap(\.kcal).reduce(0, +)
    }

    var protein: Double {
        entries.compactMap(\.protein).reduce(0, +)
    }

    var carbs: Double {
        entries.compactMap(\.carbs).reduce(0, +)
    }

    var fat: Double {
        entries.compactMap(\.fat).reduce(0, +)
    }

    var remainingEnergy: Double {
        targets.kcal - energy
    }

    var isEmpty: Bool { entries.isEmpty }
    var isOverBudget: Bool { energy > targets.kcal }
}

enum BLGWishUpsert: Sendable, Equatable {
    case inserted
    case updated
}

enum BLGStoreError: Error, Sendable, Equatable {
    case openFailed(Int32)
    case sqlite(code: Int32, action: String, message: String)
    case notOpen
}

enum BLGCatalogError: Error, Sendable, Equatable {
    case notFound
    case transport
    case malformed
    case offlineUncached
}

enum BLGGramsGate {
    static let minimum: Double = 0.1
    static let maximum: Double = 5000

    static func accept(_ grams: Double) -> Bool {
        grams >= minimum && grams <= maximum
    }
}
