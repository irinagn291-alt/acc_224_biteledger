import UIKit

/// Procedural ledger-line scan window. The centre is open; dim ink frames the rest.
final class BLGScanLineView: UIView {
    private(set) var windowRect: CGRect = .zero

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        backgroundColor = .clear
        isAccessibilityElement = true
        accessibilityLabel = "Ledger scan line"
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        isOpaque = false
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let height = max(BLGSpace.n(7), bounds.height * 0.14)
        windowRect = CGRect(
            x: bounds.minX + BLGSpace.n(2),
            y: bounds.midY - height / 2,
            width: bounds.width - BLGSpace.n(4),
            height: height
        )
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        BLGPalette.ink.withAlphaComponent(0.55).setFill()
        context.fill(bounds)
        context.setBlendMode(.clear)
        context.fill(windowRect)
        context.setBlendMode(.normal)
        BLGPalette.accent.setStroke()
        context.setLineWidth(2)
        context.stroke(windowRect.insetBy(dx: 1, dy: 1))
        BLGPalette.surface.setStroke()
        context.setLineWidth(1)
        let midY = windowRect.midY
        context.move(to: CGPoint(x: windowRect.minX + 8, y: midY))
        context.addLine(to: CGPoint(x: windowRect.maxX - 8, y: midY))
        context.strokePath()
        let tick: CGFloat = 10
        for x in [windowRect.minX, windowRect.maxX] {
            context.move(to: CGPoint(x: x, y: midY - tick))
            context.addLine(to: CGPoint(x: x, y: midY + tick))
        }
        context.strokePath()
    }
}
