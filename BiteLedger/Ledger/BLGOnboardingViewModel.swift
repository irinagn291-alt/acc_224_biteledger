import Combine
import Foundation

/// Onboarding outputs. Writes targets through the account seam and sets the completion flag.
@MainActor
final class BLGOnboardingViewModel: ObservableObject {
    let nextPage = PassthroughSubject<Void, Never>()
    let skip = PassthroughSubject<Void, Never>()
    let finish = PassthroughSubject<Void, Never>()

    @Published private(set) var page: Int = 0
    @Published var kcalText: String = "2200"
    @Published var proteinText: String = "120"
    @Published var carbsText: String = "250"
    @Published var fatText: String = "70"
    @Published private(set) var didFinish = false
    @Published private(set) var isSaving = false

    let pageCount = 4
    private let account: BLGAccountService
    private var bag = Set<AnyCancellable>()

    init(account: BLGAccountService = BLGServices.account) {
        self.account = account
        nextPage
            .sink { [weak self] in
                guard let self else { return }
                if self.page < self.pageCount - 1 {
                    self.page += 1
                }
            }
            .store(in: &bag)

        skip
            .sink { [weak self] in
                self?.blg_write(BLGTargets.sensible)
            }
            .store(in: &bag)

        finish
            .sink { [weak self] in
                self?.blg_commit()
            }
            .store(in: &bag)
    }

    private func blg_commit() {
        let kcal = BLGFormatters.parseDecimal(kcalText) ?? BLGTargets.sensible.kcal
        let protein = BLGFormatters.parseDecimal(proteinText)
        let carbs = BLGFormatters.parseDecimal(carbsText)
        let fat = BLGFormatters.parseDecimal(fatText)
        let targets = BLGTargets(
            kcal: kcal > 0 ? kcal : BLGTargets.sensible.kcal,
            protein: protein.flatMap { $0 > 0 ? $0 : nil } ?? BLGTargets.sensible.protein,
            carbs: carbs.flatMap { $0 > 0 ? $0 : nil } ?? BLGTargets.sensible.carbs,
            fat: fat.flatMap { $0 > 0 ? $0 : nil } ?? BLGTargets.sensible.fat
        )
        blg_write(targets)
    }

    private func blg_write(_ targets: BLGTargets) {
        guard isSaving == false else { return }
        isSaving = true
        account.saveTargets(targets)
            .receive(on: RunLoop.main)
            .sink { [weak self] completion in
                self?.isSaving = false
                if case .failure = completion { return }
            } receiveValue: { [weak self] _ in
                self?.account.markOnboarded()
                BLGHaptics.commit()
                self?.didFinish = true
            }
            .store(in: &bag)
    }
}
