import Foundation

/// Bundled catalogue so Lookup and Scan stay useful with no network.
enum BLGShelf {
    static let products: [BLGProduct] = [
        BLGProduct(
            barcode: "8076809545013",
            name: "Ledger Lentils Dry",
            brand: "BiteLedger Shelf",
            kcal100: 353,
            protein100: 25.8,
            carbs100: 60.1,
            fat100: 1.1,
            imageURL: nil,
            bundledAsset: "blg_ProductPlaceholder",
            lastRefresh: 0
        ),
        BLGProduct(
            barcode: "0722252100450",
            name: "Ledger Protein Bar",
            brand: "BiteLedger Shelf",
            kcal100: 383,
            protein100: 30.0,
            carbs100: 40.0,
            fat100: 12.0,
            imageURL: nil,
            bundledAsset: "blg_ProductPlaceholder",
            lastRefresh: 0
        ),
        BLGProduct(
            barcode: "0074354611200",
            name: "Ledger Hummus",
            brand: "BiteLedger Shelf",
            kcal100: 166,
            protein100: 7.9,
            carbs100: 14.3,
            fat100: 9.6,
            imageURL: nil,
            bundledAsset: "blg_ProductPlaceholder",
            lastRefresh: 0
        ),
        BLGProduct(
            barcode: "7394376616037",
            name: "Ledger Oat Milk",
            brand: "BiteLedger Shelf",
            kcal100: 45,
            protein100: 1.0,
            carbs100: 6.7,
            fat100: 1.5,
            imageURL: nil,
            bundledAsset: "blg_ProductPlaceholder",
            lastRefresh: 0
        ),
        BLGProduct(
            barcode: "3046920029759",
            name: "Ledger Dark Chocolate 70%",
            brand: "BiteLedger Shelf",
            kcal100: 598,
            protein100: 7.8,
            carbs100: 45.9,
            fat100: 42.6,
            imageURL: nil,
            bundledAsset: "blg_ProductPlaceholder",
            lastRefresh: 0
        ),
        BLGProduct(
            barcode: "8076800195057",
            name: "Ledger Pasta Spaghetti",
            brand: "BiteLedger Shelf",
            kcal100: 371,
            protein100: 13.0,
            carbs100: 74.7,
            fat100: 1.5,
            imageURL: nil,
            bundledAsset: "blg_ProductPlaceholder",
            lastRefresh: 0
        )
    ]

    static func product(barcode: String) -> BLGProduct? {
        products.first { $0.barcode == barcode }
    }

    static func matches(_ query: String) -> [BLGProduct] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if needle.isEmpty { return products }
        return products.filter { product in
            product.name.localizedCaseInsensitiveContains(needle)
                || product.brand.localizedCaseInsensitiveContains(needle)
                || product.barcode.contains(needle)
        }
    }
}
