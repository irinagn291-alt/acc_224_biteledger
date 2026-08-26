import UIKit

/// Ledger ruling drawn behind content. Decorative for VoiceOver.
final class BLGPaperView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        blg_prepare()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        blg_prepare()
    }

    private func blg_prepare() {
        backgroundColor = BLGPalette.background
        isOpaque = true
        isAccessibilityElement = false
        isUserInteractionEnabled = false
        if let texture = UIImage(named: "blg_Texture") {
            let tiled = UIColor(patternImage: texture).withAlphaComponent(0.18)
            layer.contents = nil
            backgroundColor = tiled
        }
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let context = UIGraphicsGetCurrentContext() else { return }
        BLGPalette.muted.withAlphaComponent(0.28).setStroke()
        context.setLineWidth(1)
        var y = bounds.minY + BLGSpace.n(4)
        while y < bounds.maxY {
            context.move(to: CGPoint(x: bounds.minX + BLGSpace.n(2), y: y))
            context.addLine(to: CGPoint(x: bounds.maxX - BLGSpace.n(2), y: y))
            y += BLGSpace.n(3)
        }
        context.strokePath()
        BLGPalette.accent.withAlphaComponent(0.35).setStroke()
        context.setLineWidth(1)
        let margin = bounds.minX + BLGSpace.n(7)
        context.move(to: CGPoint(x: margin, y: bounds.minY))
        context.addLine(to: CGPoint(x: margin, y: bounds.maxY))
        context.strokePath()
    }
}
