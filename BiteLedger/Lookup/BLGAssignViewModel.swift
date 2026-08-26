import Combine
import Foundation

/// Assign reducer host. Petty Cash is hidden when a future date is selected.
@MainActor
final class BLGAssignViewModel: ObservableObject {
    let selectSlot = PassthroughSubject<BLGSlot, Never>()
    let selectEaten = PassthroughSubject<Bool, Never>()
    let selectDate = PassthroughSubject<Date, Never>()
    let confirm = PassthroughSubject<Void, Never>()

    @Published var product: BLGProduct
    @Published var grams: Double
    @Published private(set) var slot: BLGSlot = .opening
    @Published private(set) var eaten = true
    @Published private(set) var dayKey: String = BLGDayKey.make(from: Date())
    @Published private(set) var posted: BLGEntry?
    @Published private(set) var isSaving = false
    @Published private(set) var notice: String?

    var availableSlots: [BLGSlot] {
        BLGSlot.allCases.filter { BLGAssignPolicy.allowsPettyCash(eaten: eaten) || $0 != .pettyCash }
    }

    private let account: BLGAccountService
    private var bag = Set<AnyCancellable>()

    init(product: BLGProduct, grams: Double, account: BLGAccountService = BLGServices.account) {
        self.product = product
        self.grams = grams
        self.account = account

        selectSlot
            .sink { [weak self] slot in
                self?.slot = BLGAssignPolicy.resolved(slot: slot, eaten: self?.eaten ?? true)
            }
            .store(in: &bag)

        selectEaten
            .sink { [weak self] eaten in
                guard let self else { return }
                self.eaten = eaten
                if eaten {
                    self.dayKey = BLGDayKey.make(from: Date())
                }
                self.slot = BLGAssignPolicy.resolved(slot: self.slot, eaten: eaten)
            }
            .store(in: &bag)

        selectDate
            .sink { [weak self] date in
                guard let self else { return }
                let key = BLGDayKey.make(from: date)
                self.dayKey = key
                let today = BLGDayKey.make(from: Date())
                self.eaten = key == today
                self.slot = BLGAssignPolicy.resolved(slot: self.slot, eaten: self.eaten)
            }
            .store(in: &bag)

        confirm
            .sink { [weak self] in self?.blg_post() }
            .store(in: &bag)
    }

    private func blg_post() {
        guard isSaving == false, BLGAssignPolicy.validateGrams(grams) else { return }
        isSaving = true
        account.post(product: product, grams: grams, slot: slot, dayKey: dayKey, eaten: eaten)
            .receive(on: RunLoop.main)
            .sink { [weak self] completion in
                self?.isSaving = false
                if case .failure = completion {
                    self?.notice = "The entry could not be posted to the ledger."
                }
            } receiveValue: { [weak self] entry in
                BLGHaptics.commit()
                self?.posted = entry
            }
            .store(in: &bag)
    }
}
