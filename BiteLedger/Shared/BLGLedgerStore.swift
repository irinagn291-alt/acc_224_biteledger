import Foundation
import SQLite3

/// Serial SQLite actor. UI never sees a statement or a cursor.
actor BLGLedgerStore {
    private var db: OpaquePointer?
    private let path: String
    private let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

    init(path: String) {
        self.path = path
    }

    func open() throws {
        if db != nil { return }
        var handle: OpaquePointer?
        let flags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX
        let code = sqlite3_open_v2(path, &handle, flags, nil)
        if code != SQLITE_OK {
            if let handle {
                sqlite3_close(handle)
            }
            throw BLGStoreError.openFailed(code)
        }
        db = handle
        try exec("PRAGMA journal_mode = WAL;")
        try exec("PRAGMA foreign_keys = ON;")
        try migrate()
        try seedShelf()
    }

    func close() {
        if let db {
            sqlite3_close(db)
        }
        db = nil
    }

    func resetAllData() throws {
        try begin()
        do {
            try exec("DELETE FROM entries;")
            try exec("DELETE FROM plans;")
            try exec("DELETE FROM wishlist;")
            try exec("DELETE FROM products;")
            try exec("DELETE FROM targets;")
            try commit()
        } catch {
            try rollback()
            throw error
        }
        try seedShelf()
        try saveTargets(BLGTargets.sensible)
    }

    func saveTargets(_ targets: BLGTargets) throws {
        let sql = "INSERT OR REPLACE INTO targets(lock, kcal, protein, carbs, fat) VALUES (1, ?, ?, ?, ?);"
        let stmt = try prepare(sql, action: "saveTargets")
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_double(stmt, 1, targets.kcal)
        bindOptionalDouble(stmt, 2, targets.protein)
        bindOptionalDouble(stmt, 3, targets.carbs)
        bindOptionalDouble(stmt, 4, targets.fat)
        try stepDone(stmt, action: "saveTargets")
    }

    func loadTargets() throws -> BLGTargets {
        let sql = "SELECT kcal, protein, carbs, fat FROM targets WHERE lock = 1 LIMIT 1;"
        let stmt = try prepare(sql, action: "loadTargets")
        defer { sqlite3_finalize(stmt) }
        if sqlite3_step(stmt) == SQLITE_ROW {
            return BLGTargets(
                kcal: sqlite3_column_double(stmt, 0),
                protein: optDouble(stmt, 1),
                carbs: optDouble(stmt, 2),
                fat: optDouble(stmt, 3)
            )
        }
        return BLGTargets.sensible
    }

    func upsertProduct(_ product: BLGProduct) throws {
        let sql = """
        INSERT OR REPLACE INTO products(barcode, name, brand, kcal100, protein100, carbs100, fat100, image_url, bundled_asset, last_refresh)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """
        let stmt = try prepare(sql, action: "upsertProduct")
        defer { sqlite3_finalize(stmt) }
        bindText(stmt, 1, product.barcode)
        bindText(stmt, 2, product.name)
        bindText(stmt, 3, product.brand)
        bindOptionalDouble(stmt, 4, product.kcal100)
        bindOptionalDouble(stmt, 5, product.protein100)
        bindOptionalDouble(stmt, 6, product.carbs100)
        bindOptionalDouble(stmt, 7, product.fat100)
        bindOptionalText(stmt, 8, product.imageURL)
        bindOptionalText(stmt, 9, product.bundledAsset)
        sqlite3_bind_int64(stmt, 10, sqlite3_int64(product.lastRefresh))
        try stepDone(stmt, action: "upsertProduct")
    }

    func product(barcode: String) throws -> BLGProduct? {
        let sql = "SELECT barcode, name, brand, kcal100, protein100, carbs100, fat100, image_url, bundled_asset, last_refresh FROM products WHERE barcode = ? LIMIT 1;"
        let stmt = try prepare(sql, action: "product")
        defer { sqlite3_finalize(stmt) }
        bindText(stmt, 1, barcode)
        if sqlite3_step(stmt) == SQLITE_ROW {
            return readProduct(stmt)
        }
        return nil
    }

    func insertEntry(_ entry: BLGEntry, planned: Bool) throws {
        let sql = planned ? Self.insertPlanSQL : Self.insertEntrySQL
        let stmt = try prepare(sql, action: planned ? "insertPlan" : "insertEntry")
        defer { sqlite3_finalize(stmt) }
        bindText(stmt, 1, entry.id)
        bindText(stmt, 2, entry.barcode)
        bindText(stmt, 3, entry.productName)
        bindText(stmt, 4, entry.brand)
        sqlite3_bind_double(stmt, 5, entry.grams)
        bindText(stmt, 6, entry.slot.rawValue)
        bindText(stmt, 7, entry.dayKey)
        bindOptionalDouble(stmt, 8, entry.kcal100)
        bindOptionalDouble(stmt, 9, entry.protein100)
        bindOptionalDouble(stmt, 10, entry.carbs100)
        bindOptionalDouble(stmt, 11, entry.fat100)
        bindOptionalText(stmt, 12, entry.imageURL)
        sqlite3_bind_int64(stmt, 13, sqlite3_int64(entry.createdAt))
        try stepDone(stmt, action: planned ? "insertPlan" : "insertEntry")
    }

    func deleteEntry(id: String) throws {
        let sql = "DELETE FROM entries WHERE id = ?;"
        let stmt = try prepare(sql, action: "deleteEntry")
        defer { sqlite3_finalize(stmt) }
        bindText(stmt, 1, id)
        try stepDone(stmt, action: "deleteEntry")
    }

    func deletePlan(id: String) throws {
        let sql = "DELETE FROM plans WHERE id = ?;"
        let stmt = try prepare(sql, action: "deletePlan")
        defer { sqlite3_finalize(stmt) }
        bindText(stmt, 1, id)
        try stepDone(stmt, action: "deletePlan")
    }

    func entries(dayKey: String) throws -> [BLGEntry] {
        try fetchRows(table: "entries", dayKey: dayKey)
    }

    func plans(from startKey: String, to endKey: String) throws -> [BLGEntry] {
        let sql = """
        SELECT id, barcode, product_name, brand, grams, slot, day_key, kcal100, protein100, carbs100, fat100, image_url, created_at
        FROM plans WHERE day_key >= ? AND day_key <= ? ORDER BY day_key ASC, created_at ASC;
        """
        let stmt = try prepare(sql, action: "plansRange")
        defer { sqlite3_finalize(stmt) }
        bindText(stmt, 1, startKey)
        bindText(stmt, 2, endKey)
        var rows: [BLGEntry] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            rows.append(readEntry(stmt))
        }
        return rows
    }

    func convertPlanToEaten(id: String, dayKey: String) throws {
        let sql = """
        SELECT id, barcode, product_name, brand, grams, slot, day_key, kcal100, protein100, carbs100, fat100, image_url, created_at
        FROM plans WHERE id = ? LIMIT 1;
        """
        let stmt = try prepare(sql, action: "loadPlan")
        defer { sqlite3_finalize(stmt) }
        bindText(stmt, 1, id)
        guard sqlite3_step(stmt) == SQLITE_ROW else { return }
        var entry = readEntry(stmt)
        entry = BLGEntry(
            id: UUID().uuidString,
            barcode: entry.barcode,
            productName: entry.productName,
            brand: entry.brand,
            grams: entry.grams,
            slot: entry.slot,
            dayKey: dayKey,
            kcal100: entry.kcal100,
            protein100: entry.protein100,
            carbs100: entry.carbs100,
            fat100: entry.fat100,
            imageURL: entry.imageURL,
            createdAt: Int(Date().timeIntervalSince1970)
        )
        try begin()
        do {
            try insertEntry(entry, planned: false)
            try deletePlan(id: id)
            try commit()
        } catch {
            try rollback()
            throw error
        }
    }

    func daySnapshot(_ dayKey: String) throws -> BLGDaySnapshot {
        BLGDaySnapshot(dayKey: dayKey, entries: try entries(dayKey: dayKey), targets: try loadTargets())
    }

    func monthEntries(prefix: String) throws -> [BLGEntry] {
        let sql = """
        SELECT id, barcode, product_name, brand, grams, slot, day_key, kcal100, protein100, carbs100, fat100, image_url, created_at
        FROM entries WHERE day_key LIKE ? ORDER BY day_key ASC, created_at ASC;
        """
        let stmt = try prepare(sql, action: "monthEntries")
        defer { sqlite3_finalize(stmt) }
        bindText(stmt, 1, prefix + "%")
        var rows: [BLGEntry] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            rows.append(readEntry(stmt))
        }
        return rows
    }

    func upsertWish(_ product: BLGProduct) throws -> BLGWishUpsert {
        if try isWished(product.barcode) {
            let sql = "UPDATE wishlist SET product_name = ?, brand = ?, kcal100 = ?, protein100 = ?, carbs100 = ?, fat100 = ?, image_url = ?, bundled_asset = ?, added_at = ? WHERE barcode = ?;"
            let stmt = try prepare(sql, action: "updateWish")
            defer { sqlite3_finalize(stmt) }
            bindText(stmt, 1, product.name)
            bindText(stmt, 2, product.brand)
            bindOptionalDouble(stmt, 3, product.kcal100)
            bindOptionalDouble(stmt, 4, product.protein100)
            bindOptionalDouble(stmt, 5, product.carbs100)
            bindOptionalDouble(stmt, 6, product.fat100)
            bindOptionalText(stmt, 7, product.imageURL)
            bindOptionalText(stmt, 8, product.bundledAsset)
            sqlite3_bind_int64(stmt, 9, sqlite3_int64(Int(Date().timeIntervalSince1970)))
            bindText(stmt, 10, product.barcode)
            try stepDone(stmt, action: "updateWish")
            return .updated
        }
        let sql = """
        INSERT INTO wishlist(barcode, product_name, brand, kcal100, protein100, carbs100, fat100, image_url, bundled_asset, added_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """
        let stmt = try prepare(sql, action: "insertWish")
        defer { sqlite3_finalize(stmt) }
        bindText(stmt, 1, product.barcode)
        bindText(stmt, 2, product.name)
        bindText(stmt, 3, product.brand)
        bindOptionalDouble(stmt, 4, product.kcal100)
        bindOptionalDouble(stmt, 5, product.protein100)
        bindOptionalDouble(stmt, 6, product.carbs100)
        bindOptionalDouble(stmt, 7, product.fat100)
        bindOptionalText(stmt, 8, product.imageURL)
        bindOptionalText(stmt, 9, product.bundledAsset)
        sqlite3_bind_int64(stmt, 10, sqlite3_int64(Int(Date().timeIntervalSince1970)))
        try stepDone(stmt, action: "insertWish")
        return .inserted
    }

    func isWished(_ barcode: String) throws -> Bool {
        let sql = "SELECT 1 FROM wishlist WHERE barcode = ? LIMIT 1;"
        let stmt = try prepare(sql, action: "isWished")
        defer { sqlite3_finalize(stmt) }
        bindText(stmt, 1, barcode)
        return sqlite3_step(stmt) == SQLITE_ROW
    }

    func wishes() throws -> [BLGWishItem] {
        let sql = "SELECT barcode, product_name, brand, kcal100, protein100, carbs100, fat100, image_url, bundled_asset, added_at FROM wishlist ORDER BY added_at DESC;"
        let stmt = try prepare(sql, action: "wishes")
        defer { sqlite3_finalize(stmt) }
        var rows: [BLGWishItem] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            rows.append(
                BLGWishItem(
                    barcode: text(stmt, 0),
                    productName: text(stmt, 1),
                    brand: text(stmt, 2),
                    kcal100: optDouble(stmt, 3),
                    protein100: optDouble(stmt, 4),
                    carbs100: optDouble(stmt, 5),
                    fat100: optDouble(stmt, 6),
                    imageURL: optText(stmt, 7),
                    bundledAsset: optText(stmt, 8),
                    addedAt: Int(sqlite3_column_int64(stmt, 9))
                )
            )
        }
        return rows
    }

    func deleteWish(barcode: String) throws {
        let sql = "DELETE FROM wishlist WHERE barcode = ?;"
        let stmt = try prepare(sql, action: "deleteWish")
        defer { sqlite3_finalize(stmt) }
        bindText(stmt, 1, barcode)
        try stepDone(stmt, action: "deleteWish")
    }

    func seedDemoDay(dayKey: String) throws {
        if try !entries(dayKey: dayKey).isEmpty { return }
        guard let oats = BLGShelf.product(barcode: "7394376616037"),
              let hummus = BLGShelf.product(barcode: "0074354611200"),
              let pasta = BLGShelf.product(barcode: "8076800195057"),
              let bar = BLGShelf.product(barcode: "0722252100450")
        else { return }
        let now = Int(Date().timeIntervalSince1970)
        let posts: [(BLGProduct, Double, BLGSlot)] = [
            (oats, 250, .opening),
            (hummus, 80, .midday),
            (pasta, 100, .closing),
            (bar, 60, .pettyCash)
        ]
        try begin()
        do {
            for (index, item) in posts.enumerated() {
                let entry = BLGEntry(
                    id: UUID().uuidString,
                    barcode: item.0.barcode,
                    productName: item.0.name,
                    brand: item.0.brand,
                    grams: item.1,
                    slot: item.2,
                    dayKey: dayKey,
                    kcal100: item.0.kcal100,
                    protein100: item.0.protein100,
                    carbs100: item.0.carbs100,
                    fat100: item.0.fat100,
                    imageURL: item.0.imageURL,
                    createdAt: now + index
                )
                try insertEntry(entry, planned: false)
            }
            try commit()
        } catch {
            try rollback()
            throw error
        }
    }

    private func fetchRows(table: String, dayKey: String) throws -> [BLGEntry] {
        let sql: String
        if table == "entries" {
            sql = """
            SELECT id, barcode, product_name, brand, grams, slot, day_key, kcal100, protein100, carbs100, fat100, image_url, created_at
            FROM entries WHERE day_key = ? ORDER BY created_at ASC;
            """
        } else {
            sql = """
            SELECT id, barcode, product_name, brand, grams, slot, day_key, kcal100, protein100, carbs100, fat100, image_url, created_at
            FROM plans WHERE day_key = ? ORDER BY created_at ASC;
            """
        }
        let stmt = try prepare(sql, action: "fetchRows")
        defer { sqlite3_finalize(stmt) }
        bindText(stmt, 1, dayKey)
        var rows: [BLGEntry] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            rows.append(readEntry(stmt))
        }
        return rows
    }

    private func migrate() throws {
        let version = try userVersion()
        if version < 1 {
            try exec(Self.schemaV1)
            try exec("PRAGMA user_version = 1;")
        }
        if try loadTargetsOptional() == nil {
            try saveTargets(BLGTargets.sensible)
        }
    }

    private func loadTargetsOptional() throws -> BLGTargets? {
        let sql = "SELECT kcal, protein, carbs, fat FROM targets WHERE lock = 1 LIMIT 1;"
        let stmt = try prepare(sql, action: "loadTargetsOptional")
        defer { sqlite3_finalize(stmt) }
        if sqlite3_step(stmt) == SQLITE_ROW {
            return BLGTargets(
                kcal: sqlite3_column_double(stmt, 0),
                protein: optDouble(stmt, 1),
                carbs: optDouble(stmt, 2),
                fat: optDouble(stmt, 3)
            )
        }
        return nil
    }

    private func seedShelf() throws {
        try begin()
        do {
            for product in BLGShelf.products {
                try upsertProduct(product)
            }
            try commit()
        } catch {
            try rollback()
            throw error
        }
    }

    private func userVersion() throws -> Int {
        let stmt = try prepare("PRAGMA user_version;", action: "user_version")
        defer { sqlite3_finalize(stmt) }
        if sqlite3_step(stmt) == SQLITE_ROW {
            return Int(sqlite3_column_int(stmt, 0))
        }
        return 0
    }

    private func prepare(_ sql: String, action: String) throws -> OpaquePointer {
        guard let db else { throw BLGStoreError.notOpen }
        var stmt: OpaquePointer?
        let code = sqlite3_prepare_v2(db, sql, -1, &stmt, nil)
        if code != SQLITE_OK {
            if let stmt { sqlite3_finalize(stmt) }
            throw sqliteError(code, action: action)
        }
        guard let stmt else {
            throw sqliteError(code, action: action)
        }
        return stmt
    }

    private func exec(_ sql: String) throws {
        guard let db else { throw BLGStoreError.notOpen }
        var err: UnsafeMutablePointer<CChar>?
        let code = sqlite3_exec(db, sql, nil, nil, &err)
        let message = err.map { String(cString: $0) } ?? ""
        if let err { sqlite3_free(err) }
        if code != SQLITE_OK {
            throw BLGStoreError.sqlite(code: code, action: sql, message: message)
        }
    }

    private func begin() throws { try exec("BEGIN IMMEDIATE;") }
    private func commit() throws { try exec("COMMIT;") }
    private func rollback() throws { try exec("ROLLBACK;") }

    private func stepDone(_ stmt: OpaquePointer, action: String) throws {
        let code = sqlite3_step(stmt)
        if code != SQLITE_DONE {
            throw sqliteError(code, action: action)
        }
    }

    private func sqliteError(_ code: Int32, action: String) -> BLGStoreError {
        let message = db.map { String(cString: sqlite3_errmsg($0)) } ?? "unknown"
        return .sqlite(code: code, action: action, message: message)
    }

    private func bindText(_ stmt: OpaquePointer, _ index: Int32, _ value: String) {
        sqlite3_bind_text(stmt, index, value, -1, transient)
    }

    private func bindOptionalText(_ stmt: OpaquePointer, _ index: Int32, _ value: String?) {
        if let value {
            bindText(stmt, index, value)
        } else {
            sqlite3_bind_null(stmt, index)
        }
    }

    private func bindOptionalDouble(_ stmt: OpaquePointer, _ index: Int32, _ value: Double?) {
        if let value {
            sqlite3_bind_double(stmt, index, value)
        } else {
            sqlite3_bind_null(stmt, index)
        }
    }

    private func text(_ stmt: OpaquePointer, _ index: Int32) -> String {
        guard let pointer = sqlite3_column_text(stmt, index) else { return "" }
        return String(cString: pointer)
    }

    private func optText(_ stmt: OpaquePointer, _ index: Int32) -> String? {
        if sqlite3_column_type(stmt, index) == SQLITE_NULL { return nil }
        let value = text(stmt, index)
        return value.isEmpty ? nil : value
    }

    private func optDouble(_ stmt: OpaquePointer, _ index: Int32) -> Double? {
        if sqlite3_column_type(stmt, index) == SQLITE_NULL { return nil }
        return sqlite3_column_double(stmt, index)
    }

    private func readProduct(_ stmt: OpaquePointer) -> BLGProduct {
        BLGProduct(
            barcode: text(stmt, 0),
            name: text(stmt, 1),
            brand: text(stmt, 2),
            kcal100: optDouble(stmt, 3),
            protein100: optDouble(stmt, 4),
            carbs100: optDouble(stmt, 5),
            fat100: optDouble(stmt, 6),
            imageURL: optText(stmt, 7),
            bundledAsset: optText(stmt, 8),
            lastRefresh: Int(sqlite3_column_int64(stmt, 9))
        )
    }

    private func readEntry(_ stmt: OpaquePointer) -> BLGEntry {
        BLGEntry(
            id: text(stmt, 0),
            barcode: text(stmt, 1),
            productName: text(stmt, 2),
            brand: text(stmt, 3),
            grams: sqlite3_column_double(stmt, 4),
            slot: BLGSlot(rawValue: text(stmt, 5)) ?? .midday,
            dayKey: text(stmt, 6),
            kcal100: optDouble(stmt, 7),
            protein100: optDouble(stmt, 8),
            carbs100: optDouble(stmt, 9),
            fat100: optDouble(stmt, 10),
            imageURL: optText(stmt, 11),
            createdAt: Int(sqlite3_column_int64(stmt, 12))
        )
    }

    private static let schemaV1 = """
    CREATE TABLE IF NOT EXISTS products (
        barcode TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        brand TEXT NOT NULL,
        kcal100 REAL,
        protein100 REAL,
        carbs100 REAL,
        fat100 REAL,
        image_url TEXT,
        bundled_asset TEXT,
        last_refresh INTEGER NOT NULL
    );
    CREATE TABLE IF NOT EXISTS entries (
        id TEXT PRIMARY KEY,
        barcode TEXT NOT NULL,
        product_name TEXT NOT NULL,
        brand TEXT NOT NULL,
        grams REAL NOT NULL,
        slot TEXT NOT NULL,
        day_key TEXT NOT NULL,
        kcal100 REAL,
        protein100 REAL,
        carbs100 REAL,
        fat100 REAL,
        image_url TEXT,
        created_at INTEGER NOT NULL
    );
    CREATE TABLE IF NOT EXISTS plans (
        id TEXT PRIMARY KEY,
        barcode TEXT NOT NULL,
        product_name TEXT NOT NULL,
        brand TEXT NOT NULL,
        grams REAL NOT NULL,
        slot TEXT NOT NULL,
        day_key TEXT NOT NULL,
        kcal100 REAL,
        protein100 REAL,
        carbs100 REAL,
        fat100 REAL,
        image_url TEXT,
        created_at INTEGER NOT NULL
    );
    CREATE TABLE IF NOT EXISTS targets (
        lock INTEGER PRIMARY KEY CHECK (lock = 1),
        kcal REAL NOT NULL,
        protein REAL,
        carbs REAL,
        fat REAL
    );
    CREATE TABLE IF NOT EXISTS wishlist (
        barcode TEXT PRIMARY KEY,
        product_name TEXT NOT NULL,
        brand TEXT NOT NULL,
        kcal100 REAL,
        protein100 REAL,
        carbs100 REAL,
        fat100 REAL,
        image_url TEXT,
        bundled_asset TEXT,
        added_at INTEGER NOT NULL
    );
    CREATE INDEX IF NOT EXISTS idx_entries_day ON entries(day_key);
    CREATE INDEX IF NOT EXISTS idx_entries_barcode ON entries(barcode);
    CREATE INDEX IF NOT EXISTS idx_plans_day ON plans(day_key);
    CREATE INDEX IF NOT EXISTS idx_plans_barcode ON plans(barcode);
    CREATE INDEX IF NOT EXISTS idx_wishlist_barcode ON wishlist(barcode);
    """

    private static let insertEntrySQL = """
    INSERT INTO entries(id, barcode, product_name, brand, grams, slot, day_key, kcal100, protein100, carbs100, fat100, image_url, created_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    """

    private static let insertPlanSQL = """
    INSERT INTO plans(id, barcode, product_name, brand, grams, slot, day_key, kcal100, protein100, carbs100, fat100, image_url, created_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    """
}
