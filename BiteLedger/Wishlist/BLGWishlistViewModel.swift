import Combine
import Foundation

/// Wish list. Duplicate barcodes update the existing row.
@MainActor
final class BLGWishlistViewModel: ObservableObject {
    let refresh = PassthroughSubject<Void, Never>()
    let delete = PassthroughSubject<String, Never>()

    @Published private(set) var items: [BLGWishItem] = []
    @Published private(set) var isLoading = false
    @Published private(set) var notice: String?

    private let account: BLGAccountService
    private var bag = Set<AnyCancellable>()
    private var inFlight = false

    init(account: BLGAccountService = BLGServices.account) {
        self.account = account
        refresh.sink { [weak self] in self?.blg_load() }.store(in: &bag)
        delete.sink { [weak self] barcode in self?.blg_delete(barcode) }.store(in: &bag)
    }

    private func blg_load() {
        inFlight = true
        Just(())
            .delay(for: .milliseconds(150), scheduler: RunLoop.main)
            .sink { [weak self] in
                if self?.inFlight == true { self?.isLoading = true }
            }
            .store(in: &bag)
        account.wishes()
            .receive(on: RunLoop.main)
            .sink { [weak self] completion in
                self?.inFlight = false
                self?.isLoading = false
                if case .failure = completion {
                    self?.notice = "The wish folio could not be opened."
                }
            } receiveValue: { [weak self] items in
                self?.items = items
            }
            .store(in: &bag)
    }

    private func blg_delete(_ barcode: String) {
        account.deleteWish(barcode: barcode)
            .receive(on: RunLoop.main)
            .sink { [weak self] completion in
                if case .failure = completion {
                    self?.notice = "The wish line could not be struck out."
                }
            } receiveValue: { [weak self] _ in
                self?.refresh.send(())
            }
            .store(in: &bag)
    }
}
