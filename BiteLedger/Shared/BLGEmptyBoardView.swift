import UIKit

/// Designed empty or error board used on Statement, Lookup, Planner and Wishlist.
final class BLGEmptyBoardView: UIView {
    let blgImageView = UIImageView()
    let blgTitleLabel = UILabel()
    let blgBodyLabel = UILabel()
    let blgActionButton = UIButton(type: .system)

    var onAction: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        blg_build()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        blg_build()
    }

    func blg_apply(image: String, title: String, body: String, action: String) {
        blgImageView.image = UIImage(named: image)
        blgTitleLabel.text = title
        blgBodyLabel.text = body
        blgActionButton.setTitle(action, for: .normal)
        blgImageView.accessibilityLabel = title
        blgActionButton.accessibilityLabel = action
    }

    private func blg_build() {
        backgroundColor = BLGPalette.surface
        clipsToBounds = true
        blgImageView.contentMode = .scaleAspectFit
        blgImageView.isAccessibilityElement = true
        blgTitleLabel.font = BLGTypography.bold(.heading)
        blgTitleLabel.textColor = BLGPalette.ink
        blgTitleLabel.textAlignment = .center
        blgTitleLabel.numberOfLines = 0
        blgTitleLabel.adjustsFontForContentSizeCategory = true
        blgBodyLabel.font = BLGTypography.font(.body)
        blgBodyLabel.textColor = BLGPalette.muted
        blgBodyLabel.textAlignment = .center
        blgBodyLabel.numberOfLines = 0
        blgBodyLabel.adjustsFontForContentSizeCategory = true
        var config = UIButton.Configuration.filled()
        config.baseForegroundColor = BLGPalette.surface
        config.baseBackgroundColor = BLGPalette.accent
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        blgActionButton.configuration = config
        blgActionButton.titleLabel?.font = BLGTypography.bold(.body)
        blgActionButton.addTarget(self, action: #selector(blg_tap), for: .touchUpInside)
        let stack = UIStackView(arrangedSubviews: [blgImageView, blgTitleLabel, blgBodyLabel, blgActionButton])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = BLGSpace.n(2)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        blgImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: BLGSpace.n(2)),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: BLGSpace.n(3)),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -BLGSpace.n(3)),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -BLGSpace.n(2)),
            blgImageView.widthAnchor.constraint(equalToConstant: 120),
            blgImageView.heightAnchor.constraint(equalToConstant: 120),
            blgActionButton.heightAnchor.constraint(greaterThanOrEqualToConstant: BLGSpace.tap)
        ])
    }

    @objc private func blg_tap() {
        onAction?()
    }
}
