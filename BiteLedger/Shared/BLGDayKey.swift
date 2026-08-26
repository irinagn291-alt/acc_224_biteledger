import Foundation

/// Day identity as `yyyy-MM-dd` in the user's calendar. Used in storage, queries and identifiers.
enum BLGDayKey {
    static func make(from date: Date, calendar: Calendar = .current) -> String {
        let start = calendar.startOfDay(for: date)
        let parts = calendar.dateComponents([.year, .month, .day], from: start)
        let year = parts.year ?? 0
        let month = parts.month ?? 0
        let day = parts.day ?? 0
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    static func date(from key: String, calendar: Calendar = .current) -> Date? {
        let bits = key.split(separator: "-")
        guard bits.count == 3,
              let year = Int(bits[0]),
              let month = Int(bits[1]),
              let day = Int(bits[2])
        else { return nil }
        var parts = DateComponents()
        parts.year = year
        parts.month = month
        parts.day = day
        return calendar.date(from: parts).map { calendar.startOfDay(for: $0) }
    }

    static func shift(_ key: String, days: Int, calendar: Calendar = .current) -> String {
        guard let date = date(from: key, calendar: calendar),
              let moved = calendar.date(byAdding: .day, value: days, to: date)
        else { return key }
        return make(from: moved, calendar: calendar)
    }

    static func monthPrefix(from key: String) -> String {
        String(key.prefix(7))
    }
}
