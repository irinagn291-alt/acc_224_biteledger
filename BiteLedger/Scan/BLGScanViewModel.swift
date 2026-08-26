import Combine
import Foundation

enum BLGScanPermission: Equatable {
    case unknown
    case ready
    case denied
    case restricted
    case noDevice
}

enum BLGScanResolve: Equatable {
    case idle
    case loading
    case failed(String)
}

/// Scan inputs. Capture payloads are debounced and de-duplicated here.
@MainActor
final class BLGScanViewModel: ObservableObject {
    let appear = PassthroughSubject<Void, Never>()
    let decoded = PassthroughSubject<String, Never>()
    let manual = PassthroughSubject<String, Never>()
    let retry = PassthroughSubject<Void, Never>()

    @Published private(set) var permission: BLGScanPermission = .unknown
    @Published private(set) var resolve: BLGScanResolve = .idle
    @Published private(set) var product: BLGProduct?
    @Published var manualText: String = ""

    private let account: BLGAccountService
    private var bag = Set<AnyCancellable>()
    private var lastPayload: String = ""
    private var lastAt: Date = .distantPast
    private var lastRaw: String = ""

    init(account: BLGAccountService = BLGServices.account) {
        self.account = account

        decoded
            .sink { [weak self] raw in
                self?.blg_consider(raw)
            }
            .store(in: &bag)

        manual
            .sink { [weak self] raw in
                self?.blg_lookup(raw)
            }
            .store(in: &bag)

        retry
            .sink { [weak self] in
                guard let self else { return }
                self.blg_lookup(self.lastRaw)
            }
            .store(in: &bag)
    }

    func blg_setPermission(_ value: BLGScanPermission) {
        permission = value
    }

    private func blg_consider(_ raw: String) {
        let now = Date()
        if raw == lastPayload, now.timeIntervalSince(lastAt) < 1.8 {
            return
        }
        if now.timeIntervalSince(lastAt) < 1.6 {
            return
        }
        lastPayload = raw
        lastAt = now
        blg_lookup(raw)
    }

    private func blg_lookup(_ raw: String) {
        lastRaw = raw
        product = nil
        resolve = .loading
        account.resolve(raw: raw)
            .receive(on: RunLoop.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    if let catalog = error as? BLGCatalogError {
                        switch catalog {
                        case .notFound:
                            self?.resolve = .failed("No product folio for that code. Enter it by hand or try another packet.")
                        case .offlineUncached:
                            self?.resolve = .failed("This code is not on the shelf and the wire is down. Retry when you have a line.")
                        case .transport:
                            self?.resolve = .failed("The catalogue line failed. Retry the same code.")
                        case .malformed:
                            self?.resolve = .failed("The catalogue sent a page we could not read.")
                        }
                    } else {
                        self?.resolve = .failed("The catalogue line failed. Retry the same code.")
                    }
                }
            } receiveValue: { [weak self] product in
                self?.resolve = .idle
                self?.product = product
            }
            .store(in: &bag)
    }
}
