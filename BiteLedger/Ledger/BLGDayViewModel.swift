import Combine
import Collections
import Foundation
import UIKit

/// Ledger front page. Publishes day totals and slot ledgers; inputs are PassthroughSubjects.
@MainActor
final class BLGDayViewModel: ObservableObject {
    let refresh = PassthroughSubject<Void, Never>()
    let shiftDay = PassthroughSubject<Int, Never>()

    @Published private(set) var dayKey: String
    @Published private(set) var snapshot = BLGDaySnapshot(dayKey: "", entries: [], targets: .sensible)
    @Published private(set) var lines: [BLGLedgerLine] = []
    @Published private(set) var bySlot: OrderedDictionary<BLGSlot, [BLGEntry]> = [:]
    @Published private(set) var isLoading = false
    @Published private(set) var notice: String?

    private let account: BLGAccountService
    private var bag = Set<AnyCancellable>()
    private var inFlight = false
    private var loadingWork: AnyCancellable?

    init(account: BLGAccountService = BLGServices.account, dayKey: String = BLGDayKey.make(from: Date())) {
        self.account = account
        self.dayKey = dayKey

        refresh
            .sink { [weak self] in self?.blg_load() }
            .store(in: &bag)

        shiftDay
            .sink { [weak self] delta in
                guard let self else { return }
                self.dayKey = BLGDayKey.shift(self.dayKey, days: delta)
                self.blg_load()
            }
            .store(in: &bag)

        NotificationCenter.default.publisher(for: .NSCalendarDayChanged)
            .merge(with: NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification))
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                let today = BLGDayKey.make(from: Date())
                if self.dayKey != today {
                    self.dayKey = today
                    self.blg_load()
                }
            }
            .store(in: &bag)
    }

    private func blg_load() {
        inFlight = true
        notice = nil
        loadingWork = Just(())
            .delay(for: .milliseconds(150), scheduler: RunLoop.main)
            .sink { [weak self] in
                if self?.inFlight == true {
                    self?.isLoading = true
                }
            }
        account.snapshot(dayKey: dayKey)
            .receive(on: RunLoop.main)
            .sink { [weak self] completion in
                self?.inFlight = false
                self?.isLoading = false
                if case .failure = completion {
                    self?.notice = "The day book could not be opened. Try again."
                }
            } receiveValue: { [weak self] snapshot in
                guard let self else { return }
                self.snapshot = snapshot
                self.lines = BLGDoubleEntry.lines(entries: snapshot.entries, budget: snapshot.targets.kcal)
                var grouped = OrderedDictionary<BLGSlot, [BLGEntry]>()
                for slot in BLGSlot.allCases {
                    let rows = snapshot.entries.filter { $0.slot == slot }
                    grouped[slot] = rows
                }
                self.bySlot = grouped
            }
            .store(in: &bag)
    }
}
