import UIKit

/// Typed design tokens. The only place UIKit reads named colours and Georgia.
enum BLGPalette {
    static var background: UIColor { named("blg_background") }
    static var surface: UIColor { named("blg_surface") }
    static var ink: UIColor { named("blg_ink") }
    static var accent: UIColor { named("blg_accent") }
    static var muted: UIColor { named("blg_muted") }

    private static func named(_ name: String) -> UIColor {
        UIColor(named: name) ?? .systemBackground
    }
}

enum BLGTypeStep: CaseIterable {
    case display
    case title
    case heading
    case body
    case caption
    case figure
}

enum BLGTypography {
    static func font(_ step: BLGTypeStep) -> UIFont {
        let point: CGFloat
        let style: UIFont.TextStyle
        switch step {
        case .display:
            point = 34
            style = .largeTitle
        case .title:
            point = 24
            style = .title2
        case .heading:
            point = 20
            style = .title3
        case .body:
            point = 17
            style = .body
        case .caption:
            point = 13
            style = .footnote
        case .figure:
            return UIFontMetrics(forTextStyle: .body).scaledFont(
                for: UIFont.monospacedDigitSystemFont(ofSize: 17, weight: .regular)
            )
        }
        let face = UIFont(name: "Georgia", size: point) ?? UIFont.systemFont(ofSize: point)
        return UIFontMetrics(forTextStyle: style).scaledFont(for: face)
    }

    static func bold(_ step: BLGTypeStep) -> UIFont {
        let point: CGFloat
        let style: UIFont.TextStyle
        switch step {
        case .display:
            point = 34
            style = .largeTitle
        case .title:
            point = 24
            style = .title2
        case .heading:
            point = 20
            style = .title3
        case .body:
            point = 17
            style = .body
        case .caption:
            point = 13
            style = .footnote
        case .figure:
            return UIFontMetrics(forTextStyle: .body).scaledFont(
                for: UIFont.monospacedDigitSystemFont(ofSize: 17, weight: .semibold)
            )
        }
        let face = UIFont(name: "Georgia-Bold", size: point) ?? UIFont.boldSystemFont(ofSize: point)
        return UIFontMetrics(forTextStyle: style).scaledFont(for: face)
    }
}

enum BLGSpace {
    static let unit: CGFloat = 8
    static func n(_ count: CGFloat) -> CGFloat { unit * count }
    static let radius: CGFloat = 0
    static let tap: CGFloat = 44
}

@MainActor
enum BLGMotion {
    static let duration: TimeInterval = 0.28
    static let options: UIView.AnimationOptions = .curveEaseInOut

    static func animate(_ changes: @escaping @MainActor () -> Void, completion: (@MainActor (Bool) -> Void)? = nil) {
        if UIAccessibility.isReduceMotionEnabled {
            changes()
            completion?(true)
            return
        }
        UIView.animate(withDuration: duration, delay: 0, options: options) {
            changes()
        } completion: { finished in
            completion?(finished)
        }
    }
}

@MainActor
enum BLGFormatters {
    static let kcal: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter
    }()

    static let macro: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 0
        return formatter
    }()

    static let grams: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 0
        return formatter
    }()

    static func kcalText(_ value: Double) -> String {
        kcal.string(from: NSNumber(value: value.rounded())) ?? "—"
    }

    static func macroText(_ value: Double?) -> String {
        guard let value else { return "—" }
        return macro.string(from: NSNumber(value: value)) ?? "—"
    }

    static func gramsText(_ value: Double) -> String {
        grams.string(from: NSNumber(value: value)) ?? "—"
    }

    static func parseDecimal(_ raw: String) -> Double? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }
        return grams.number(from: trimmed)?.doubleValue
    }
}
