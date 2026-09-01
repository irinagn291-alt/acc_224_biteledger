import CoreImage
import UIKit

/// Reviewer demo payload. QR encodes the bundled oat-milk EAN so Scan can finish without a packet.
enum BLGDemoBarcode {
    static let code = "7394376616037"
    static let productName = "Ledger Oat Milk"

    static func qrImage(dimension: CGFloat = 720) -> UIImage? {
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(Data(code.utf8), forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel")
        guard let raw = filter.outputImage,
              let color = CIFilter(name: "CIFalseColor")
        else { return nil }
        color.setValue(raw, forKey: kCIInputImageKey)
        color.setValue(CIColor.black, forKey: "inputColor0")
        color.setValue(CIColor.white, forKey: "inputColor1")
        guard let tinted = color.outputImage else { return nil }
        let scale = max(dimension / max(tinted.extent.width, 1), 1)
        let scaled = tinted.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let pad: CGFloat = 48
        let canvas = CIImage(color: .white).cropped(to: CGRect(
            x: 0,
            y: 0,
            width: scaled.extent.width + pad * 2,
            height: scaled.extent.height + pad * 2
        ))
        let placed = scaled.transformed(by: CGAffineTransform(translationX: pad, y: pad)).composited(over: canvas)
        let context = CIContext(options: [.useSoftwareRenderer: true])
        guard let cgImage = context.createCGImage(placed, from: placed.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

/// Full-screen demo QR so Review can scan from a second screen or photograph the image.
@MainActor
final class BLGDemoBarcodeViewController: UIViewController {
    var onPost: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Demo barcode"
        view.backgroundColor = BLGPalette.background
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Close",
            style: .done,
            target: self,
            action: #selector(blg_close)
        )

        let imageView = UIImageView(image: BLGDemoBarcode.qrImage())
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .white
        imageView.accessibilityLabel = "Demo QR for Ledger Oat Milk"
        imageView.isAccessibilityElement = true

        let titleLabel = UILabel()
        titleLabel.text = BLGDemoBarcode.productName
        titleLabel.font = BLGTypography.bold(.heading)
        titleLabel.textColor = BLGPalette.ink
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.adjustsFontForContentSizeCategory = true

        let codeLabel = UILabel()
        codeLabel.text = BLGDemoBarcode.code
        codeLabel.font = BLGTypography.font(.figure)
        codeLabel.textColor = BLGPalette.accent
        codeLabel.textAlignment = .center
        codeLabel.adjustsFontForContentSizeCategory = true
        codeLabel.accessibilityLabel = "Barcode \(BLGDemoBarcode.code)"

        let body = UILabel()
        body.text = "Scan this QR with Scan on another device, or type the digits into Type a barcode. The local shelf resolves Ledger Oat Milk offline."
        body.font = BLGTypography.font(.caption)
        body.textColor = BLGPalette.muted
        body.textAlignment = .center
        body.numberOfLines = 0
        body.adjustsFontForContentSizeCategory = true

        let useButton = UIButton(type: .system)
        BLGStyle.accentButton(useButton, title: "Post this code")
        useButton.addAction(UIAction { [weak self] _ in
            self?.blg_post()
        }, for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [imageView, titleLabel, codeLabel, body, useButton])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16)
        ])
    }

    @objc private func blg_close() {
        dismiss(animated: true)
    }

    private func blg_post() {
        let post = onPost
        dismiss(animated: true) {
            post?()
        }
    }
}
