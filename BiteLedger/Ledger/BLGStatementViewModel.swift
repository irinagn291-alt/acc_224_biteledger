import Combine
import Foundation

/// Statement scene: running balance, day switching and CSV export text.
@MainActor
final class BLGStatementViewModel: ObservableObject {
    let refresh = PassthroughSubject<Void, Never>()
    let shiftDay = PassthroughSubject<Int, Never>()
    let delete = PassthroughSubject<String, Never>()
    let export = PassthroughSubject<Void, Never>()

    @Published private(set) var dayKey: String
    @Published private(set) var lines: [BLGLedgerLine] = []
    @Published private(set) var snapshot = BLGDaySnapshot(dayKey: "", entries: [], targets: .sensible)
    @Published private(set) var csvText: String = ""
    @Published private(set) var monthTitle: String = ""
    @Published private(set) var isLoading = false
    @Published private(set) var notice: String?
    @Published var highlightedID: String?

    private let account: BLGAccountService
    private var bag = Set<AnyCancellable>()
    private var inFlight = false

    init(account: BLGAccountService = BLGServices.account, dayKey: String = BLGDayKey.make(from: Date())) {
        self.account = account
        self.dayKey = dayKey

        refresh.sink { [weak self] in self?.blg_load() }.store(in: &bag)
        shiftDay.sink { [weak self] delta in
            guard let self else { return }
            self.dayKey = BLGDayKey.shift(self.dayKey, days: delta)
            self.blg_load()
        }.store(in: &bag)
        delete.sink { [weak self] id in self?.blg_delete(id) }.store(in: &bag)
        export.sink { [weak self] in self?.blg_export() }.store(in: &bag)
    }

    private func blg_load() {
        inFlight = true
        Just(())
            .delay(for: .milliseconds(150), scheduler: RunLoop.main)
            .sink { [weak self] in
                if self?.inFlight == true { self?.isLoading = true }
            }
            .store(in: &bag)
        account.snapshot(dayKey: dayKey)
            .receive(on: RunLoop.main)
            .sink { [weak self] completion in
                self?.inFlight = false
                self?.isLoading = false
                if case .failure = completion {
                    self?.notice = "This statement page could not be posted."
                }
            } receiveValue: { [weak self] snapshot in
                guard let self else { return }
                self.snapshot = snapshot
                self.lines = BLGDoubleEntry.lines(entries: snapshot.entries, budget: snapshot.targets.kcal)
                self.monthTitle = BLGDayKey.monthPrefix(from: snapshot.dayKey)
                self.csvText = BLGCSVExport.statement(lines: self.lines, budget: snapshot.targets.kcal)
            }
            .store(in: &bag)
    }

    private func blg_delete(_ id: String) {
        account.deleteEntry(id: id)
            .receive(on: RunLoop.main)
            .sink { [weak self] completion in
                if case .failure = completion {
                    self?.notice = "The line could not be struck out."
                }
            } receiveValue: { [weak self] _ in
                self?.refresh.send(())
            }
            .store(in: &bag)
    }

    private func blg_export() {
        csvText = BLGCSVExport.statement(lines: lines, budget: snapshot.targets.kcal)
    }
}
