import Foundation

/// Pure assign reducer. Petty Cash cannot be planned; future dates remap it to Midday.
enum BLGAssignPolicy {
    static func resolved(slot: BLGSlot, eaten: Bool) -> BLGSlot {
        if !eaten && slot == .pettyCash {
            return .midday
        }
        return slot
    }

    static func allowsPettyCash(eaten: Bool) -> Bool {
        eaten
    }

    static func validateGrams(_ grams: Double) -> Bool {
        BLGGramsGate.accept(grams)
    }
}
