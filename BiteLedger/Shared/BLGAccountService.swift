import Combine
import Foundation

/// Domain seam between ViewModels and storage. Exposes Combine publishers; never imports UIKit.
final class BLGAccountService: Sendable {
    static let onboardingKey = "blg.onboarding.complete"
    static let demoKey = "blg.demo.v1"

    let store: BLGLedgerStore
    let catalog: BLGCatalogClient

    init(store: BLGLedgerStore, catalog: BLGCatalogClient) {
        self.store = store
        self.catalog = catalog
    }

    func start() -> AnyPublisher<Void, Error> {
        future {
            try await self.store.open()
            await self.seedDemoIfNeeded()
        }
    }

    func snapshot(dayKey: String) -> AnyPublisher<BLGDaySnapshot, Error> {
        future { try await self.store.daySnapshot(dayKey) }
    }

    func monthLines(dayKey: String) -> AnyPublisher<(targets: BLGTargets, lines: [BLGLedgerLine]), Error> {
        future {
            let targets = try await self.store.loadTargets()
            let prefix = BLGDayKey.monthPrefix(from: dayKey)
            let rows = try await self.store.monthEntries(prefix: prefix)
            return (targets, BLGDoubleEntry.lines(entries: rows, budget: targets.kcal))
        }
    }

    func plans(from startKey: String, to endKey: String) -> AnyPublisher<[BLGEntry], Error> {
        future { try await self.store.plans(from: startKey, to: endKey) }
    }

    func wishes() -> AnyPublisher<[BLGWishItem], Error> {
        future { try await self.store.wishes() }
    }

    func isWished(_ barcode: String) -> AnyPublisher<Bool, Error> {
        future { try await self.store.isWished(barcode) }
    }

    func post(product: BLGProduct, grams: Double, slot: BLGSlot, dayKey: String, eaten: Bool) -> AnyPublisher<BLGEntry, Error> {
        future {
            let resolved = BLGAssignPolicy.resolved(slot: slot, eaten: eaten)
            try await self.store.upsertProduct(product)
            let entry = BLGEntry(
                id: UUID().uuidString,
                barcode: product.barcode,
                productName: product.name,
                brand: product.brand,
                grams: grams,
                slot: resolved,
                dayKey: dayKey,
                kcal100: product.kcal100,
                protein100: product.protein100,
                carbs100: product.carbs100,
                fat100: product.fat100,
                imageURL: product.imageURL,
                createdAt: Int(Date().timeIntervalSince1970)
            )
            try await self.store.insertEntry(entry, planned: !eaten)
            return entry
        }
    }

    func deleteEntry(id: String) -> AnyPublisher<Void, Error> {
        future { try await self.store.deleteEntry(id: id) }
    }

    func deletePlan(id: String) -> AnyPublisher<Void, Error> {
        future { try await self.store.deletePlan(id: id) }
    }

    func convertPlan(id: String, dayKey: String) -> AnyPublisher<Void, Error> {
        future { try await self.store.convertPlanToEaten(id: id, dayKey: dayKey) }
    }

    func addWish(_ product: BLGProduct) -> AnyPublisher<BLGWishUpsert, Error> {
        future {
            try await self.store.upsertProduct(product)
            return try await self.store.upsertWish(product)
        }
    }

    func deleteWish(barcode: String) -> AnyPublisher<Void, Error> {
        future { try await self.store.deleteWish(barcode: barcode) }
    }

    func saveTargets(_ targets: BLGTargets) -> AnyPublisher<Void, Error> {
        future { try await self.store.saveTargets(targets) }
    }

    func loadTargets() -> AnyPublisher<BLGTargets, Error> {
        future { try await self.store.loadTargets() }
    }

    func resetAllData() -> AnyPublisher<Void, Error> {
        future { try await self.store.resetAllData() }
    }

    func cachedProduct(barcode: String) -> AnyPublisher<BLGProduct?, Error> {
        future { try await self.store.product(barcode: barcode) }
    }

    func cache(_ product: BLGProduct) -> AnyPublisher<Void, Error> {
        future { try await self.store.upsertProduct(product) }
    }

    func search(terms: String) -> AnyPublisher<[BLGProduct], Error> {
        let local = BLGShelf.matches(terms)
        return catalog.searchPublisher(terms: terms)
            .map { remote in Self.merge(remote: remote, local: local) }
            .catch { error -> AnyPublisher<[BLGProduct], Error> in
                if local.isEmpty {
                    return Fail(error: error).eraseToAnyPublisher()
                }
                return Just(local).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    func resolve(raw: String) -> AnyPublisher<BLGProduct, Error> {
        let codes = BLGBarcodeNormalizer.candidates(from: raw)
        guard !codes.isEmpty else {
            return Fail(error: BLGCatalogError.notFound).eraseToAnyPublisher()
        }
        return resolveCandidates(codes, index: 0)
    }

    var isOnboarded: Bool {
        UserDefaults.standard.bool(forKey: Self.onboardingKey)
    }

    func markOnboarded() {
        UserDefaults.standard.set(true, forKey: Self.onboardingKey)
    }

    func clearOnboarding() {
        UserDefaults.standard.set(false, forKey: Self.onboardingKey)
    }

    private func resolveCandidates(_ codes: [String], index: Int) -> AnyPublisher<BLGProduct, Error> {
        guard index < codes.count else {
            return Fail(error: BLGCatalogError.notFound).eraseToAnyPublisher()
        }
        let code = codes[index]
        return future { try await self.store.product(barcode: code) }
            .flatMap { cached -> AnyPublisher<BLGProduct, Error> in
                if let cached {
                    return Just(cached).setFailureType(to: Error.self).eraseToAnyPublisher()
                }
                if let shelf = BLGShelf.product(barcode: code) {
                    return self.cache(shelf).map { shelf }.eraseToAnyPublisher()
                }
                return self.catalog.productPublisher(code: code)
                    .flatMap { product in
                        self.cache(product).map { product }
                    }
                    .catch { error -> AnyPublisher<BLGProduct, Error> in
                        if index + 1 < codes.count {
                            return self.resolveCandidates(codes, index: index + 1)
                        }
                        if let catalog = error as? BLGCatalogError, catalog == .notFound {
                            return Fail(error: BLGCatalogError.notFound).eraseToAnyPublisher()
                        }
                        return Fail(error: BLGCatalogError.offlineUncached).eraseToAnyPublisher()
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    private func seedDemoIfNeeded() async {
        #if targetEnvironment(simulator)
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: Self.demoKey) == false else { return }
        let day = BLGDayKey.make(from: Date())
        do {
            try await store.seedDemoDay(dayKey: day)
            defaults.set(true, forKey: Self.demoKey)
            markOnboarded()
        } catch {
            return
        }
        #endif
    }

    static func merge(remote: [BLGProduct], local: [BLGProduct]) -> [BLGProduct] {
        var seen: Set<String> = []
        var merged: [BLGProduct] = []
        for product in remote + local {
            if product.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { continue }
            if seen.insert(product.barcode).inserted {
                merged.append(product)
            }
        }
        return merged
    }

    private func future<T: Sendable>(_ work: @escaping @Sendable () async throws -> T) -> AnyPublisher<T, Error> {
        Future { promise in
            let hopper = BLGPromiseHopper(promise)
            Task {
                do {
                    hopper.finish(.success(try await work()))
                } catch {
                    hopper.finish(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

/// Bridges a Combine `Future` promise into a Task. Completed once; no shared mutable state after that.
final class BLGPromiseHopper<T: Sendable>: @unchecked Sendable {
    private let promise: Future<T, Error>.Promise

    init(_ promise: @escaping Future<T, Error>.Promise) {
        self.promise = promise
    }

    func finish(_ result: Result<T, Error>) {
        promise(result)
    }
}
