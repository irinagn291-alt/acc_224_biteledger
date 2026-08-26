import Combine
import Collections
import Foundation

/// Fourteen-day plan horizon. Converting a row posts it as eaten today.
@MainActor
final class BLGPlannerViewModel: ObservableObject {
    static let horizonDays = 14

    let refresh = PassthroughSubject<Void, Never>()
    let convert = PassthroughSubject<String, Never>()
    let delete = PassthroughSubject<String, Never>()

    @Published private(set) var byDay: OrderedDictionary<String, [BLGEntry]> = [:]
    @Published private(set) var isLoading = false
    @Published private(set) var notice: String?

    private let account: BLGAccountService
    private var bag = Set<AnyCancellable>()
    private var inFlight = false

    init(account: BLGAccountService = BLGServices.account) {
        self.account = account
        refresh.sink { [weak self] in self?.blg_load() }.store(in: &bag)
        convert.sink { [weak self] id in self?.blg_convert(id) }.store(in: &bag)
        delete.sink { [weak self] id in self?.blg_delete(id) }.store(in: &bag)
    }

    private func blg_load() {
        inFlight = true
        Just(())
            .delay(for: .milliseconds(150), scheduler: RunLoop.main)
            .sink { [weak self] in
                if self?.inFlight == true { self?.isLoading = true }
            }
            .store(in: &bag)
        let start = BLGDayKey.shift(BLGDayKey.make(from: Date()), days: 1)
        let end = BLGDayKey.shift(start, days: Self.horizonDays - 1)
        account.plans(from: start, to: end)
            .receive(on: RunLoop.main)
            .sink { [weak self] completion in
                self?.inFlight = false
                self?.isLoading = false
                if case .failure = completion {
                    self?.notice = "The planner folio could not be opened."
                }
            } receiveValue: { [weak self] rows in
                var grouped = OrderedDictionary<String, [BLGEntry]>()
                for row in rows {
                    grouped[row.dayKey, default: []].append(row)
                }
                self?.byDay = grouped
            }
            .store(in: &bag)
    }

    private func blg_convert(_ id: String) {
        account.convertPlan(id: id, dayKey: BLGDayKey.make(from: Date()))
            .receive(on: RunLoop.main)
            .sink { [weak self] completion in
                if case .failure = completion {
                    self?.notice = "That plan line could not be posted as eaten."
                }
            } receiveValue: { [weak self] _ in
                BLGHaptics.commit()
                self?.refresh.send(())
            }
            .store(in: &bag)
    }

    private func blg_delete(_ id: String) {
        account.deletePlan(id: id)
            .receive(on: RunLoop.main)
            .sink { [weak self] completion in
                if case .failure = completion {
                    self?.notice = "The plan line could not be struck out."
                }
            } receiveValue: { [weak self] _ in
                self?.refresh.send(())
            }
            .store(in: &bag)
    }
}
