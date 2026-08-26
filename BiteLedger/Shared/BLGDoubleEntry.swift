import Foundation

/// Twist: each eaten row is a debit against the day's energy budget with a running balance.
struct BLGLedgerLine: Sendable, Hashable, Identifiable {
    var id: String { entry.id }
    let entry: BLGEntry
    let debitKcal: Double?
    let balanceAfter: Double
}

enum BLGDoubleEntry {
    static func lines(entries: [BLGEntry], budget: Double) -> [BLGLedgerLine] {
        let ordered = entries.sorted { lhs, rhs in
            if lhs.createdAt == rhs.createdAt {
                return lhs.id < rhs.id
            }
            return lhs.createdAt < rhs.createdAt
        }
        var balance = budget
        return ordered.map { entry in
            if let debit = entry.kcal {
                balance -= debit
                return BLGLedgerLine(entry: entry, debitKcal: debit, balanceAfter: balance)
            }
            return BLGLedgerLine(entry: entry, debitKcal: nil, balanceAfter: balance)
        }
    }
}
