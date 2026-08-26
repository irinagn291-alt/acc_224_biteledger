import Combine
import UIKit

/// Three-tier thumbnail: remote URL, bundled shelf asset, then `blg_ProductPlaceholder`.
@MainActor
enum BLGProductArt {
    static func apply(
        to imageView: UIImageView,
        imageURL: String?,
        bundledAsset: String?,
        bag: inout Set<AnyCancellable>
    ) {
        imageView.image = UIImage(named: bundledAsset ?? "blg_ProductPlaceholder") ?? UIImage(named: "blg_ProductPlaceholder")
        imageView.isAccessibilityElement = false
        guard let imageURL, let url = URL(string: imageURL) else { return }
        var request = URLRequest(url: url)
        request.setValue(BLGCatalogClient.userAgent, forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15
        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { data in
                if let image = UIImage(data: data) {
                    imageView.image = image
                }
            })
            .store(in: &bag)
    }
}

@MainActor
enum BLGStyle {
    static func paper(_ view: UIView) {
        view.backgroundColor = BLGPalette.background
    }

    static func inkLabel(_ label: UILabel, step: BLGTypeStep, bold: Bool = false) {
        label.font = bold ? BLGTypography.bold(step) : BLGTypography.font(step)
        label.textColor = BLGPalette.ink
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = false
    }

    static func mutedLabel(_ label: UILabel, step: BLGTypeStep) {
        label.font = BLGTypography.font(step)
        label.textColor = BLGPalette.muted
        label.adjustsFontForContentSizeCategory = true
    }

    static func ledgerField(_ field: UITextField) {
        field.font = BLGTypography.font(.body)
        field.textColor = BLGPalette.ink
        field.backgroundColor = BLGPalette.surface
        field.layer.borderColor = BLGPalette.muted.cgColor
        field.layer.borderWidth = 1
        field.layer.cornerRadius = BLGSpace.radius
        field.adjustsFontForContentSizeCategory = true
        let pad = UIView(frame: CGRect(x: 0, y: 0, width: BLGSpace.n(1.5), height: BLGSpace.tap))
        field.leftView = pad
        field.leftViewMode = .always
    }

    static func accentButton(_ button: UIButton, title: String) {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.baseForegroundColor = BLGPalette.surface
        config.baseBackgroundColor = BLGPalette.accent
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        button.configuration = config
        button.titleLabel?.font = BLGTypography.bold(.body)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: BLGSpace.tap).isActive = true
        button.accessibilityLabel = title
    }

    static func ghostButton(_ button: UIButton, title: String) {
        var config = UIButton.Configuration.bordered()
        config.title = title
        config.baseForegroundColor = BLGPalette.ink
        config.background.backgroundColor = BLGPalette.surface
        config.background.strokeColor = BLGPalette.ink
        config.background.strokeWidth = 1
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        button.configuration = config
        button.titleLabel?.font = BLGTypography.font(.body)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: BLGSpace.tap).isActive = true
        button.accessibilityLabel = title
    }
}
