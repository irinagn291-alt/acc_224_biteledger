import Combine
import Foundation

enum BLGLookupState: Equatable {
    case idle
    case loading
    case results
    case empty
    case failed
}

/// Debounced search. Cancels the previous publisher via `switchToLatest`.
@MainActor
final class BLGLookupViewModel: ObservableObject {
    let queryChanged = PassthroughSubject<String, Never>()
    let retry = PassthroughSubject<Void, Never>()

    @Published private(set) var products: [BLGProduct] = []
    @Published private(set) var state: BLGLookupState = .idle
    @Published private(set) var notice: String?

    private let account: BLGAccountService
    private var bag = Set<AnyCancellable>()
    private var lastQuery = ""
    private var inFlight = false

    init(account: BLGAccountService = BLGServices.account) {
        self.account = account

        let queries = queryChanged
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .removeDuplicates()
            .handleEvents(receiveOutput: { [weak self] text in
                self?.lastQuery = text
                if text.isEmpty {
                    self?.products = BLGShelf.products
                    self?.state = .idle
                    self?.notice = nil
                }
            })
            .filter { $0.isEmpty == false }
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .share()

        queries
            .map { [account] terms -> AnyPublisher<[BLGProduct], Never> in
                Just(())
                    .delay(for: .milliseconds(150), scheduler: RunLoop.main)
                    .handleEvents(receiveOutput: { [weak self] _ in
                        self?.state = .loading
                    })
                    .flatMap { _ in
                        account.search(terms: terms)
                            .map { Optional($0) }
                            .replaceError(with: nil)
                    }
                    .map { $0 ?? [] }
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .receive(on: RunLoop.main)
            .sink { [weak self] rows in
                guard let self else { return }
                if self.lastQuery.isEmpty {
                    self.products = BLGShelf.products
                    self.state = .idle
                    return
                }
                self.products = rows
                if rows.isEmpty {
                    self.state = .empty
                    self.notice = "No folio matched that name. Try another term or open the shelf."
                } else {
                    self.state = .results
                    self.notice = nil
                }
            }
            .store(in: &bag)

        retry
            .sink { [weak self] in
                guard let self else { return }
                self.queryChanged.send(self.lastQuery)
            }
            .store(in: &bag)

        products = BLGShelf.products
    }
}
