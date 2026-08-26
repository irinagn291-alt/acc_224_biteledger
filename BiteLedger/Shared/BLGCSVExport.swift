import Foundation

enum BLGCSVExport {
    static func statement(lines: [BLGLedgerLine], budget: Double) -> String {
        var rows: [String] = ["Day,Slot,Product,Barcode,Grams,DebitKcal,Balance"]
        rows.append(csv([
            lines.first?.entry.dayKey ?? "",
            "Opening balance",
            "",
            "",
            "",
            "",
            plain(budget)
        ]))
        for line in lines {
            rows.append(csv([
                line.entry.dayKey,
                line.entry.slot.label,
                line.entry.productName,
                line.entry.barcode,
                plain(line.entry.grams),
                line.debitKcal.map(plain) ?? "",
                plain(line.balanceAfter)
            ]))
        }
        return rows.joined(separator: "\n")
    }

    private static func plain(_ value: Double) -> String {
        String(value)
    }

    private static func csv(_ fields: [String]) -> String {
        fields.map(escape).joined(separator: ",")
    }

    private static func escape(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return field
    }
}
