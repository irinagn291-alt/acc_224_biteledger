import Combine
import UIKit

final class BLGProductCell: UITableViewCell {
    @IBOutlet weak var blgThumbView: UIImageView!
    @IBOutlet weak var blgNameLabel: UILabel!
    @IBOutlet weak var blgBrandLabel: UILabel!
    @IBOutlet weak var blgKcalLabel: UILabel!
    private var artBag = Set<AnyCancellable>()

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        blg_install()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        artBag = Set<AnyCancellable>()
    }

    func blg_bind(_ product: BLGProduct) {
        blg_style()
        blgNameLabel?.text = product.name
        blgBrandLabel?.text = product.brand.isEmpty ? "Unbranded" : product.brand
        blgKcalLabel?.text = product.kcal100.map { BLGFormatters.kcalText($0) + " /100 g" } ?? "unknown /100 g"
        BLGProductArt.apply(to: blgThumbView ?? UIImageView(), imageURL: product.imageURL, bundledAsset: product.bundledAsset, bag: &artBag)
        accessibilityLabel = "\(product.name), \(blgKcalLabel?.text ?? "")"
    }

    private func blg_style() {
        backgroundColor = BLGPalette.surface
        BLGStyle.inkLabel(blgNameLabel ?? UILabel(), step: .body, bold: true)
        blgNameLabel?.lineBreakMode = .byTruncatingTail
        BLGStyle.mutedLabel(blgBrandLabel ?? UILabel(), step: .caption)
        blgKcalLabel?.font = BLGTypography.font(.figure)
        blgKcalLabel?.textColor = BLGPalette.ink
        blgKcalLabel?.textAlignment = .right
        blgKcalLabel?.setContentCompressionResistancePriority(.required, for: .horizontal)
        blgThumbView?.contentMode = .scaleAspectFill
        blgThumbView?.clipsToBounds = true
        blgThumbView?.isAccessibilityElement = false
    }

    private func blg_install() {
        let thumb = UIImageView()
        let name = UILabel()
        let brand = UILabel()
        let kcal = UILabel()
        blgThumbView = thumb
        blgNameLabel = name
        blgBrandLabel = brand
        blgKcalLabel = kcal
        let text = UIStackView(arrangedSubviews: [name, brand])
        text.axis = .vertical
        text.spacing = 2
        let row = UIStackView(arrangedSubviews: [thumb, text, kcal])
        row.alignment = .center
        row.spacing = BLGSpace.n(1.5)
        row.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(row)
        thumb.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: BLGSpace.n(2)),
            row.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -BLGSpace.n(2)),
            row.topAnchor.constraint(equalTo: contentView.topAnchor, constant: BLGSpace.n(1)),
            row.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -BLGSpace.n(1)),
            thumb.widthAnchor.constraint(equalToConstant: 44),
            thumb.heightAnchor.constraint(equalToConstant: 44)
        ])
        blg_style()
    }
}
