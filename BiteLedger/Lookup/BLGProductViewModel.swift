import Combine
import Foundation

/// Detail card. Live portion totals from grams input; never stores rounded values.
@MainActor
final class BLGProductViewModel: ObservableObject {
    let gramsChanged = PassthroughSubject<String, Never>()
    let addWish = PassthroughSubject<Void, Never>()

    @Published private(set) var product: BLGProduct
    @Published private(set) var grams: Double = 100
    @Published private(set) var gramsValid = true
    @Published private(set) var liveKcal: Double?
    @Published private(set) var liveProtein: Double?
    @Published private(set) var liveCarbs: Double?
    @Published private(set) var liveFat: Double?
    @Published private(set) var wished = false
    @Published private(set) var wishBusy = false
    @Published private(set) var notice: String?

    private let account: BLGAccountService
    private var bag = Set<AnyCancellable>()

    init(product: BLGProduct, account: BLGAccountService = BLGServices.account) {
        self.product = product
        self.account = account
        blg_recompute()

        gramsChanged
            .sink { [weak self] text in
                self?.blg_applyGrams(text)
            }
            .store(in: &bag)

        addWish
            .sink { [weak self] in self?.blg_wish() }
            .store(in: &bag)

        account.isWished(product.barcode)
            .receive(on: RunLoop.main)
            .sink { _ in } receiveValue: { [weak self] flag in
                self?.wished = flag
            }
            .store(in: &bag)
    }

    private func blg_applyGrams(_ text: String) {
        guard let parsed = BLGFormatters.parseDecimal(text) else {
            gramsValid = text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            return
        }
        gramsValid = BLGGramsGate.accept(parsed)
        if gramsValid {
            grams = parsed
            blg_recompute()
        }
    }

    private func blg_recompute() {
        liveKcal = BLGPortionMath.portion(per100: product.kcal100, grams: grams)
        liveProtein = BLGPortionMath.portion(per100: product.protein100, grams: grams)
        liveCarbs = BLGPortionMath.portion(per100: product.carbs100, grams: grams)
        liveFat = BLGPortionMath.portion(per100: product.fat100, grams: grams)
    }

    private func blg_wish() {
        guard wished == false, wishBusy == false else { return }
        wishBusy = true
        account.addWish(product)
            .receive(on: RunLoop.main)
            .sink { [weak self] completion in
                self?.wishBusy = false
                if case .failure = completion {
                    self?.notice = "The wish folio could not be saved."
                }
            } receiveValue: { [weak self] result in
                self?.wished = true
                if result == .inserted {
                    BLGHaptics.commit()
                }
            }
            .store(in: &bag)
    }
}
