import UIKit

/// Procedural ledger-line scan window. The centre is open; dim ink frames the rest.
final class BLGScanLineView: UIView {
    private(set) var windowRect: CGRect = .zero

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        backgroundColor = .clear
        isAccessibilityElement = true
        accessibilityLabel = "Ledger scan window for barcode or QR"
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        isOpaque = false
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }

    /// Square region used for `rectOfInterest`. A thin ledger line cannot hold a QR.
    private(set) var detectionRect: CGRect = .zero

    override func layoutSubviews() {
        super.layoutSubviews()
        let inset = BLGSpace.n(2)
        let usable = bounds.insetBy(dx: inset, dy: inset)
        let side = min(usable.width, max(usable.height * 0.72, BLGSpace.n(22)))
        detectionRect = CGRect(
            x: usable.midX - side / 2,
            y: usable.midY - side / 2,
            width: side,
            height: side
        )
        let lineHeight = max(BLGSpace.n(7), bounds.height * 0.14)
        windowRect = CGRect(
            x: detectionRect.minX,
            y: detectionRect.midY - lineHeight / 2,
            width: detectionRect.width,
            height: lineHeight
        )
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        BLGPalette.ink.withAlphaComponent(0.55).setFill()
        context.fill(bounds)
        context.setBlendMode(.clear)
        context.fill(detectionRect)
        context.setBlendMode(.normal)
        BLGPalette.accent.setStroke()
        context.setLineWidth(2)
        context.stroke(detectionRect.insetBy(dx: 1, dy: 1))
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
