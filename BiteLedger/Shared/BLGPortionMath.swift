import Foundation

/// Portion maths. Stored values stay full precision; callers round only at display.
enum BLGPortionMath {
    static func kcal100(energyKcal100g: Double?, energyKj100g: Double?) -> Double? {
        if let energyKcal100g {
            return energyKcal100g
        }
        if let energyKj100g {
            return energyKj100g / 4.184
        }
        return nil
    }

    static func portion(per100: Double?, grams: Double) -> Double? {
        guard let per100 else { return nil }
        return per100 * grams / 100
    }
}
