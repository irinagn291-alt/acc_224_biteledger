import UIKit

/// Statement / ledger prototype cell. Numbers keep their column; names truncate.
final class BLGEntryCell: UITableViewCell {
    @IBOutlet weak var blgIconView: UIImageView!
    @IBOutlet weak var blgNameLabel: UILabel!
    @IBOutlet weak var blgMetaLabel: UILabel!
    @IBOutlet weak var blgDebitLabel: UILabel!
    @IBOutlet weak var blgBalanceLabel: UILabel!

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

    func blg_bind(line: BLGLedgerLine, highlight: Bool) {
        blg_style()
        blgIconView?.image = UIImage(named: line.entry.slot.assetName)
        blgIconView?.isAccessibilityElement = false
        blgNameLabel?.text = line.entry.productName
        blgMetaLabel?.text = "\(line.entry.slot.label) · \(BLGFormatters.gramsText(line.entry.grams)) g"
        blgDebitLabel?.text = line.debitKcal.map { "−" + BLGFormatters.kcalText($0) } ?? "—"
        blgBalanceLabel?.text = BLGFormatters.kcalText(line.balanceAfter)
        backgroundColor = highlight ? BLGPalette.accent.withAlphaComponent(0.12) : BLGPalette.surface
        accessibilityLabel = "\(line.entry.productName), debit \(blgDebitLabel?.text ?? ""), balance \(blgBalanceLabel?.text ?? "")"
    }

    func blg_bind(entry: BLGEntry, highlight: Bool) {
        blg_style()
        blgIconView?.image = UIImage(named: entry.slot.assetName)
        blgNameLabel?.text = entry.productName
        blgMetaLabel?.text = "\(entry.slot.label) · \(BLGFormatters.gramsText(entry.grams)) g"
        blgDebitLabel?.text = entry.kcal.map { "−" + BLGFormatters.kcalText($0) } ?? "—"
        blgBalanceLabel?.text = ""
        backgroundColor = highlight ? BLGPalette.accent.withAlphaComponent(0.12) : BLGPalette.surface
        accessibilityLabel = "\(entry.productName), \(blgDebitLabel?.text ?? "")"
    }

    private func blg_style() {
        backgroundColor = BLGPalette.surface
        BLGStyle.inkLabel(blgNameLabel ?? UILabel(), step: .body, bold: true)
        blgNameLabel?.lineBreakMode = .byTruncatingTail
        BLGStyle.mutedLabel(blgMetaLabel ?? UILabel(), step: .caption)
        blgDebitLabel?.font = BLGTypography.font(.figure)
        blgDebitLabel?.textColor = BLGPalette.accent
        blgDebitLabel?.textAlignment = .right
        blgDebitLabel?.adjustsFontForContentSizeCategory = true
        blgBalanceLabel?.font = BLGTypography.font(.figure)
        blgBalanceLabel?.textColor = BLGPalette.ink
        blgBalanceLabel?.textAlignment = .right
        blgBalanceLabel?.adjustsFontForContentSizeCategory = true
        blgDebitLabel?.setContentCompressionResistancePriority(.required, for: .horizontal)
        blgBalanceLabel?.setContentCompressionResistancePriority(.required, for: .horizontal)
        blgNameLabel?.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    private func blg_install() {
        let icon = UIImageView()
        let name = UILabel()
        let meta = UILabel()
        let debit = UILabel()
        let balance = UILabel()
        blgIconView = icon
        blgNameLabel = name
        blgMetaLabel = meta
        blgDebitLabel = debit
        blgBalanceLabel = balance
        let text = UIStackView(arrangedSubviews: [name, meta])
        text.axis = .vertical
        text.spacing = 2
        let numbers = UIStackView(arrangedSubviews: [debit, balance])
        numbers.axis = .vertical
        numbers.alignment = .trailing
        numbers.spacing = 2
        let row = UIStackView(arrangedSubviews: [icon, text, numbers])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = BLGSpace.n(1.5)
        row.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(row)
        icon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: BLGSpace.n(2)),
            row.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -BLGSpace.n(2)),
            row.topAnchor.constraint(equalTo: contentView.topAnchor, constant: BLGSpace.n(1)),
            row.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -BLGSpace.n(1)),
            icon.widthAnchor.constraint(equalToConstant: 36),
            icon.heightAnchor.constraint(equalToConstant: 36)
        ])
        blg_style()
    }
}
