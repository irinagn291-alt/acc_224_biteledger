import Combine
import Foundation

/// Goals editor plus onboarding replay and confirmed data reset.
@MainActor
final class BLGGoalsViewModel: ObservableObject {
    let save = PassthroughSubject<Void, Never>()
    let reset = PassthroughSubject<Void, Never>()
    let reload = PassthroughSubject<Void, Never>()

    @Published var kcalText: String = ""
    @Published var proteinText: String = ""
    @Published var carbsText: String = ""
    @Published var fatText: String = ""
    @Published private(set) var notice: String?
    @Published private(set) var saved = false
    @Published private(set) var isSaving = false

    private let account: BLGAccountService
    private var bag = Set<AnyCancellable>()

    init(account: BLGAccountService = BLGServices.account) {
        self.account = account
        reload.sink { [weak self] in self?.blg_load() }.store(in: &bag)
        save.sink { [weak self] in self?.blg_save() }.store(in: &bag)
        reset.sink { [weak self] in self?.blg_reset() }.store(in: &bag)
    }

    private func blg_load() {
        account.loadTargets()
            .receive(on: RunLoop.main)
            .sink { _ in } receiveValue: { [weak self] targets in
                guard let self else { return }
                self.kcalText = BLGFormatters.kcalText(targets.kcal)
                self.proteinText = BLGFormatters.macroText(targets.protein)
                self.carbsText = BLGFormatters.macroText(targets.carbs)
                self.fatText = BLGFormatters.macroText(targets.fat)
                if self.proteinText == "—" { self.proteinText = "" }
                if self.carbsText == "—" { self.carbsText = "" }
                if self.fatText == "—" { self.fatText = "" }
            }
            .store(in: &bag)
    }

    private func blg_save() {
        guard let kcal = BLGFormatters.parseDecimal(kcalText), kcal > 0, kcal < 20000 else {
            notice = "Energy must be a positive number of kcal."
            return
        }
        guard let protein = optionalMacro(proteinText),
              let carbs = optionalMacro(carbsText),
              let fat = optionalMacro(fatText)
        else {
            notice = "A macro must be empty or a number from 0 to 1000."
            return
        }
        isSaving = true
        account.saveTargets(BLGTargets(kcal: kcal, protein: protein, carbs: carbs, fat: fat))
            .receive(on: RunLoop.main)
            .sink { [weak self] completion in
                self?.isSaving = false
                if case .failure = completion {
                    self?.notice = "Targets could not be ruled into the book."
                }
            } receiveValue: { [weak self] _ in
                BLGHaptics.commit()
                self?.saved = true
                self?.notice = nil
            }
            .store(in: &bag)
    }

    private func blg_reset() {
        account.resetAllData()
            .receive(on: RunLoop.main)
            .sink { [weak self] completion in
                if case .failure = completion {
                    self?.notice = "The ledger could not be wiped."
                }
            } receiveValue: { [weak self] _ in
                BLGHaptics.commit()
                self?.reload.send(())
            }
            .store(in: &bag)
    }

    private func optionalMacro(_ text: String) -> Double?? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed == "—" { return .some(nil) }
        guard let value = BLGFormatters.parseDecimal(trimmed), value >= 0, value <= 1000 else {
            return nil
        }
        return .some(value)
    }
}
