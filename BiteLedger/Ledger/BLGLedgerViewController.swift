import Combine
import UIKit

/// Ledger front page. Energy, macros, four slots and the running-balance twist surface.
@MainActor
final class BLGLedgerViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var blgScrollView: UIScrollView!
    @IBOutlet weak var blgHeaderDecor: UIImageView!
    @IBOutlet weak var blgDayLabel: UILabel!
    @IBOutlet weak var blgEnergyLabel: UILabel!
    @IBOutlet weak var blgEnergyTargetLabel: UILabel!
    @IBOutlet weak var blgBalanceLabel: UILabel!
    @IBOutlet weak var blgProteinIcon: UIImageView!
    @IBOutlet weak var blgCarbsIcon: UIImageView!
    @IBOutlet weak var blgFatIcon: UIImageView!
    @IBOutlet weak var blgProteinLabel: UILabel!
    @IBOutlet weak var blgCarbsLabel: UILabel!
    @IBOutlet weak var blgFatLabel: UILabel!
    @IBOutlet weak var blgTableView: UITableView!
    @IBOutlet weak var blgLookupButton: UIButton!
    @IBOutlet weak var blgScanButton: UIButton!
    @IBOutlet weak var blgStatementButton: UIButton!
    @IBOutlet weak var blgEmptyBoard: BLGEmptyBoardView!
    @IBOutlet weak var blgOverLabel: UILabel!
    @IBOutlet weak var blgTableHeight: NSLayoutConstraint!

    private let viewModel = BLGDayViewModel()
    private var bag = Set<AnyCancellable>()
    private var didShowEnergy = false
    private var lastEnergy: Double = 0
    private var staggerDone = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Ledger"
        BLGStyle.paper(view)
        blgHeaderDecor.image = UIImage(named: "blg_HeaderDecor")
        blgHeaderDecor.isAccessibilityElement = false
        blgHeaderDecor.contentMode = .scaleAspectFill
        BLGStyle.inkLabel(blgDayLabel, step: .heading, bold: true)
        blgEnergyLabel.font = BLGTypography.bold(.display)
        blgEnergyLabel.textColor = BLGPalette.accent
        blgEnergyLabel.adjustsFontForContentSizeCategory = true
        BLGStyle.mutedLabel(blgEnergyTargetLabel, step: .body)
        blgBalanceLabel.font = BLGTypography.font(.figure)
        blgBalanceLabel.textColor = BLGPalette.ink
        blgBalanceLabel.adjustsFontForContentSizeCategory = true
        blgProteinIcon.image = UIImage(named: "blg_MacroProtein")
        blgCarbsIcon.image = UIImage(named: "blg_MacroCarbs")
        blgFatIcon.image = UIImage(named: "blg_MacroFat")
        [blgProteinIcon, blgCarbsIcon, blgFatIcon].forEach { icon in
            icon?.isAccessibilityElement = false
        }
        [blgProteinLabel, blgCarbsLabel, blgFatLabel].forEach { BLGStyle.inkLabel($0, step: .caption) }
        BLGStyle.accentButton(blgLookupButton, title: "Lookup")
        BLGStyle.accentButton(blgScanButton, title: "Scan")
        BLGStyle.ghostButton(blgStatementButton, title: "Open statement")
        blgOverLabel.font = BLGTypography.bold(.caption)
        blgOverLabel.textColor = BLGPalette.accent
        blgOverLabel.adjustsFontForContentSizeCategory = true
        blgTableView.dataSource = self
        blgTableView.delegate = self
        blgTableView.rowHeight = 72
        blgTableView.backgroundColor = .clear
        blgTableView.separatorColor = BLGPalette.muted
        blgTableView.register(BLGEntryCell.self, forCellReuseIdentifier: "BLGEntryCell")
        blgEmptyBoard.blg_apply(
            image: "blg_EmptyLog",
            title: "No postings today",
            body: "The page is ruled and waiting. Lookup a food or scan a packet.",
            action: "Lookup a product"
        )
        blgEmptyBoard.onAction = { [weak self] in
            self?.performSegue(withIdentifier: "blg_showLookup", sender: nil)
        }
        bind()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.refresh.send(())
    }

    private func bind() {
        viewModel.$snapshot
            .combineLatest(viewModel.$lines, viewModel.$dayKey)
            .receive(on: RunLoop.main)
            .sink { [weak self] snapshot, lines, dayKey in
                self?.blg_render(snapshot: snapshot, lines: lines, dayKey: dayKey)
            }
            .store(in: &bag)
    }

    private func blg_render(snapshot: BLGDaySnapshot, lines: [BLGLedgerLine], dayKey: String) {
        blgDayLabel.text = dayKey
        let energy = snapshot.energy
        if didShowEnergy && lastEnergy != energy {
            if UIAccessibility.isReduceMotionEnabled {
                blgEnergyLabel.text = BLGFormatters.kcalText(energy)
            } else {
                let shown = lastEnergy
                UIView.transition(with: blgEnergyLabel, duration: BLGMotion.duration, options: .transitionCrossDissolve) {
                    self.blgEnergyLabel.text = BLGFormatters.kcalText(energy)
                }
                _ = shown
            }
        } else {
            blgEnergyLabel.text = BLGFormatters.kcalText(energy)
        }
        didShowEnergy = true
        lastEnergy = energy
        blgEnergyTargetLabel.text = "of " + BLGFormatters.kcalText(snapshot.targets.kcal) + " kcal"
        let balance = lines.last?.balanceAfter ?? snapshot.targets.kcal
        blgBalanceLabel.text = "Running balance  " + BLGFormatters.kcalText(balance)
        blgBalanceLabel.accessibilityLabel = "Running balance " + BLGFormatters.kcalText(balance) + " kilocalories"
        blgProteinLabel.text = "Protein " + BLGFormatters.macroText(snapshot.protein) + " / " + BLGFormatters.macroText(snapshot.targets.protein)
        blgCarbsLabel.text = "Carbs " + BLGFormatters.macroText(snapshot.carbs) + " / " + BLGFormatters.macroText(snapshot.targets.carbs)
        blgFatLabel.text = "Fat " + BLGFormatters.macroText(snapshot.fat) + " / " + BLGFormatters.macroText(snapshot.targets.fat)
        blgOverLabel.isHidden = snapshot.isOverBudget == false
        blgOverLabel.text = snapshot.isOverBudget ? "Over budget" : nil
        blgEmptyBoard.isHidden = snapshot.isEmpty == false
        blgTableView.isHidden = snapshot.isEmpty
        blgTableHeight?.constant = CGFloat(max(BLGSlot.allCases.count, 1)) * 72
        blgTableView.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        BLGSlot.allCases.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BLGEntryCell", for: indexPath) as? BLGEntryCell ?? BLGEntryCell(style: .default, reuseIdentifier: "BLGEntryCell")
        let slot = BLGSlot.allCases[indexPath.row]
        let rows = viewModel.bySlot[slot] ?? []
        let kcal = rows.compactMap(\.kcal).reduce(0, +)
        cell.blgIconView?.image = UIImage(named: slot.assetName)
        cell.blgNameLabel?.text = slot.label
        if rows.isEmpty {
            cell.blgMetaLabel?.text = "No postings"
            cell.blgDebitLabel?.text = "—"
        } else {
            let first = rows[0]
            let grams = BLGFormatters.gramsText(first.grams)
            if rows.count == 1 {
                cell.blgMetaLabel?.text = "\(first.productName) · \(grams) g"
            } else {
                cell.blgMetaLabel?.text = "\(first.productName) · \(grams) g · \(rows.count) lines"
            }
            cell.blgDebitLabel?.text = "−" + BLGFormatters.kcalText(kcal)
        }
        cell.blgBalanceLabel?.text = ""
        cell.backgroundColor = BLGPalette.surface
        cell.accessibilityLabel = slot.label
        return cell
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard staggerDone == false, UIAccessibility.isReduceMotionEnabled == false else { return }
        cell.alpha = 0
        UIView.animate(withDuration: BLGMotion.duration, delay: min(Double(indexPath.row) * 0.04, 0.2), options: BLGMotion.options) {
            cell.alpha = 1
        }
        if indexPath.row == BLGSlot.allCases.count - 1 {
            staggerDone = true
        }
    }

    @IBAction func blg_openLookup(_ sender: Any) {
        performSegue(withIdentifier: "blg_showLookup", sender: nil)
    }

    @IBAction func blg_openScan(_ sender: Any) {
        performSegue(withIdentifier: "blg_showScan", sender: nil)
    }

    @IBAction func blg_openStatement(_ sender: Any) {
        if let drawer = blg_drawer {
            drawer.blg_open(.statement)
        } else {
            performSegue(withIdentifier: "blg_showStatement", sender: nil)
        }
    }

    @IBAction func blg_prevDay(_ sender: Any) {
        viewModel.shiftDay.send(-1)
    }

    @IBAction func blg_nextDay(_ sender: Any) {
        viewModel.shiftDay.send(1)
    }
}
