import Foundation

/// Extracts EAN / UPC runs from camera text, typed fields and pasted URLs.
enum BLGBarcodeNormalizer {
    static func candidates(from raw: String) -> [String] {
        var found: [String] = []
        var seen: Set<String> = []
        var current = ""
        for character in raw {
            if character.isNumber {
                current.append(character)
            } else {
                appendRun(current, into: &found, seen: &seen)
                current = ""
            }
        }
        appendRun(current, into: &found, seen: &seen)
        return found
    }

    static func normalized(_ raw: String) -> String? {
        candidates(from: raw).first
    }

    private static func appendRun(_ run: String, into found: inout [String], seen: inout Set<String>) {
        let length = run.count
        guard length >= 8, length <= 14 else { return }
        push(run, into: &found, seen: &seen)
        if length == 12 {
            push("0" + run, into: &found, seen: &seen)
        }
        if length == 14, run.hasPrefix("0") {
            push(String(run.dropFirst()), into: &found, seen: &seen)
        }
    }

    private static func push(_ value: String, into found: inout [String], seen: inout Set<String>) {
        if seen.insert(value).inserted {
            found.append(value)
        }
    }
}
