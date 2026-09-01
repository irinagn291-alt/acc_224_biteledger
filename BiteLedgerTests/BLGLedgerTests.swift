import XCTest
@testable import BiteLedger

final class BLGLedgerTests: XCTestCase {
    func testPortionMathIncludesKjFallback() {
        XCTAssertEqual(BLGPortionMath.kcal100(energyKcal100g: 120, energyKj100g: 900), 120)
        let fromKj = BLGPortionMath.kcal100(energyKcal100g: nil, energyKj100g: 418.4)
        XCTAssertEqual(fromKj ?? 0, 100, accuracy: 0.001)
        XCTAssertNil(BLGPortionMath.kcal100(energyKcal100g: nil, energyKj100g: nil))
        XCTAssertEqual(BLGPortionMath.portion(per100: 200, grams: 50), 100)
        XCTAssertNil(BLGPortionMath.portion(per100: nil, grams: 50))
    }

    func testBarcodeNormalisation() {
        XCTAssertEqual(BLGBarcodeNormalizer.normalized("12345670"), "12345670")
        XCTAssertEqual(BLGBarcodeNormalizer.normalized("3017620422003"), "3017620422003")
        XCTAssertEqual(BLGBarcodeNormalizer.candidates(from: "072225210045"), ["072225210045", "0072225210045"])
        XCTAssertEqual(BLGBarcodeNormalizer.normalized("https://world.openfoodfacts.org/product/3017620422003/nutella"), "3017620422003")
        XCTAssertNil(BLGBarcodeNormalizer.normalized("no-digits-here"))
        XCTAssertNil(BLGBarcodeNormalizer.normalized("1234567"))
        XCTAssertEqual(BLGBarcodeNormalizer.normalized("7394376616037"), "7394376616037")
        XCTAssertEqual(
            BLGBarcodeNormalizer.normalized("https://world.openfoodfacts.org/product/7394376616037/oat-milk"),
            "7394376616037"
        )
        let gs1 = BLGBarcodeNormalizer.candidates(from: "https://id.gs1.org/01/07394376616037")
        XCTAssertTrue(gs1.contains("07394376616037"))
        XCTAssertTrue(gs1.contains("7394376616037"))
        XCTAssertTrue(BLGBarcodeNormalizer.candidates(from: "(01)07394376616037").contains("7394376616037"))
    }

    func testMissingMacroStaysUnknown() {
        let product = BLGProduct(
            barcode: "000",
            name: "Blank",
            brand: "",
            kcal100: 80,
            protein100: nil,
            carbs100: nil,
            fat100: nil,
            imageURL: nil,
            bundledAsset: nil,
            lastRefresh: 0
        )
        XCTAssertNil(BLGPortionMath.portion(per100: product.protein100, grams: 100))
        XCTAssertNil(BLGPortionMath.portion(per100: product.carbs100, grams: 40))
        XCTAssertNotEqual(BLGPortionMath.portion(per100: product.protein100, grams: 100) ?? -1, 0)
    }

    func testDayTotalsAcrossFourSlots() {
        let day = "2026-08-25"
        func entry(id: String, slot: BLGSlot, kcal100: Double, grams: Double) -> BLGEntry {
            BLGEntry(
                id: id,
                barcode: id,
                productName: id,
                brand: "",
                grams: grams,
                slot: slot,
                dayKey: day,
                kcal100: kcal100,
                protein100: 10,
                carbs100: 10,
                fat100: 10,
                imageURL: nil,
                createdAt: 1
            )
        }
        let rows = [
            entry(id: "a", slot: .opening, kcal100: 100, grams: 100),
            entry(id: "b", slot: .midday, kcal100: 200, grams: 50),
            entry(id: "c", slot: .closing, kcal100: 300, grams: 100),
            entry(id: "d", slot: .pettyCash, kcal100: 400, grams: 25)
        ]
        let snapshot = BLGDaySnapshot(dayKey: day, entries: rows, targets: .sensible)
        XCTAssertEqual(snapshot.energy, 100 + 100 + 300 + 100)
        XCTAssertEqual(rows.map(\.slot).sorted { $0.rawValue < $1.rawValue }.count, 4)
    }

    func testWishUniquenessDuplicateUpdates() async throws {
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".sqlite").path
        let store = BLGLedgerStore(path: path)
        try await store.open()
        let first = BLGShelf.products[0]
        let second = BLGProduct(
            barcode: first.barcode,
            name: "Updated name",
            brand: "New brand",
            kcal100: first.kcal100,
            protein100: first.protein100,
            carbs100: first.carbs100,
            fat100: first.fat100,
            imageURL: nil,
            bundledAsset: first.bundledAsset,
            lastRefresh: 2
        )
        let inserted = try await store.upsertWish(first)
        let updated = try await store.upsertWish(second)
        XCTAssertEqual(inserted, .inserted)
        XCTAssertEqual(updated, .updated)
        let wishes = try await store.wishes()
        XCTAssertEqual(wishes.count, 1)
        XCTAssertEqual(wishes.first?.productName, "Updated name")
    }

    func testDayBoundaryAcrossDST() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York") ?? .current
        var parts = DateComponents()
        parts.year = 2026
        parts.month = 3
        parts.day = 8
        parts.hour = 10
        let spring = calendar.date(from: parts)
        XCTAssertNotNil(spring)
        guard let spring else { return }
        let key = BLGDayKey.make(from: spring, calendar: calendar)
        XCTAssertEqual(key, "2026-03-08")
        let start = calendar.startOfDay(for: spring)
        let next = calendar.date(byAdding: .day, value: 1, to: start)
        XCTAssertEqual(BLGDayKey.make(from: next ?? start, calendar: calendar), "2026-03-09")
        if let next {
            let hours = calendar.dateComponents([.hour], from: start, to: next).hour
            XCTAssertEqual(hours, 23)
        }
    }

    func testOpenFoodFactsDecodingFlexibleNutriments() throws {
        let json = """
        {
          "status": 1,
          "code": "3017620422003",
          "product": {
            "code": "3017620422003",
            "product_name": "Nutella",
            "brands": "Ferrero",
            "nutriments": {
              "energy-kcal_100g": "539",
              "energy_100g": 2252,
              "proteins_100g": "6.3",
              "carbohydrates_100g": 57.5,
              "fat_100g": null
            }
          }
        }
        """.data(using: .utf8) ?? Data()
        let dto = try JSONDecoder().decode(BLGProductResponseDTO.self, from: json)
        let product = dto.product?.mapped()
        XCTAssertEqual(product?.name, "Nutella")
        XCTAssertEqual(product?.kcal100, 539)
        XCTAssertEqual(product?.protein100, 6.3)
        XCTAssertEqual(product?.carbs100, 57.5)
        XCTAssertNil(product?.fat100)
        let missing = """
        {"status":0,"code":"000","product":{}}
        """.data(using: .utf8) ?? Data()
        let empty = try JSONDecoder().decode(BLGProductResponseDTO.self, from: missing)
        XCTAssertEqual(empty.status, 0)
    }

    func testDoubleEntryRunningBalance() {
        let day = "2026-08-25"
        let first = BLGEntry(
            id: "1", barcode: "1", productName: "A", brand: "", grams: 100,
            slot: .opening, dayKey: day, kcal100: 200, protein100: nil, carbs100: nil, fat100: nil,
            imageURL: nil, createdAt: 10
        )
        let second = BLGEntry(
            id: "2", barcode: "2", productName: "B", brand: "", grams: 50,
            slot: .midday, dayKey: day, kcal100: 100, protein100: nil, carbs100: nil, fat100: nil,
            imageURL: nil, createdAt: 20
        )
        let unknown = BLGEntry(
            id: "3", barcode: "3", productName: "C", brand: "", grams: 10,
            slot: .pettyCash, dayKey: day, kcal100: nil, protein100: nil, carbs100: nil, fat100: nil,
            imageURL: nil, createdAt: 30
        )
        let lines = BLGDoubleEntry.lines(entries: [second, unknown, first], budget: 500)
        XCTAssertEqual(lines.count, 3)
        XCTAssertEqual(lines[0].entry.id, "1")
        XCTAssertEqual(lines[0].balanceAfter, 300)
        XCTAssertEqual(lines[1].balanceAfter, 250)
        XCTAssertNil(lines[2].debitKcal)
        XCTAssertEqual(lines[2].balanceAfter, 250)
        let csv = BLGCSVExport.statement(lines: lines, budget: 500)
        XCTAssertTrue(csv.contains("Opening balance"))
        XCTAssertTrue(csv.contains("Day,Slot,Product"))
    }

    func testAssignPolicyRejectsPettyCashOnPlan() {
        XCTAssertEqual(BLGAssignPolicy.resolved(slot: .pettyCash, eaten: false), .midday)
        XCTAssertEqual(BLGAssignPolicy.resolved(slot: .pettyCash, eaten: true), .pettyCash)
        XCTAssertFalse(BLGAssignPolicy.allowsPettyCash(eaten: false))
        XCTAssertTrue(BLGAssignPolicy.allowsPettyCash(eaten: true))
        XCTAssertFalse(BLGAssignPolicy.validateGrams(0))
        XCTAssertFalse(BLGAssignPolicy.validateGrams(-4))
        XCTAssertTrue(BLGAssignPolicy.validateGrams(80))
    }

    func testPersistenceRoundTrip() async throws {
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".sqlite").path
        let store = BLGLedgerStore(path: path)
        try await store.open()
        let product = BLGShelf.products[3]
        try await store.upsertProduct(product)
        let entry = BLGEntry(
            id: "round-trip",
            barcode: product.barcode,
            productName: product.name,
            brand: product.brand,
            grams: 250,
            slot: .opening,
            dayKey: "2026-08-25",
            kcal100: product.kcal100,
            protein100: product.protein100,
            carbs100: product.carbs100,
            fat100: product.fat100,
            imageURL: product.imageURL,
            createdAt: 1_700_000_000
        )
        try await store.insertEntry(entry, planned: false)
        try await store.saveTargets(BLGTargets(kcal: 2100, protein: 90, carbs: 200, fat: 60))
        await store.close()
        let reopened = BLGLedgerStore(path: path)
        try await reopened.open()
        let snapshot = try await reopened.daySnapshot("2026-08-25")
        XCTAssertEqual(snapshot.entries.count, 1)
        XCTAssertEqual(snapshot.entries.first?.id, "round-trip")
        XCTAssertEqual(snapshot.entries.first?.grams, 250)
        XCTAssertEqual(snapshot.targets.kcal, 2100)
        XCTAssertEqual(snapshot.targets.protein, 90)
    }
}
