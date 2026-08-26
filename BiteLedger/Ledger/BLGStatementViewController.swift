import Combine
import UIKit

/// Full statement: eaten lines, running balance, day switch and CSV export.
@MainActor
final class BLGStatementViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var blgMonthLabel: UILabel!
    @IBOutlet weak var blgDayLabel: UILabel!
    @IBOutlet weak var blgTableView: UITableView!
    @IBOutlet weak var blgExportButton: UIButton!
    @IBOutlet weak var blgEmptyBoard: BLGEmptyBoardView!
    @IBOutlet weak var blgHero: UIImageView!

    private let viewModel = BLGStatementViewModel()
    private var bag = Set<AnyCancellable>()
    private var staggerDone = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Statement"
        BLGStyle.paper(view)
        BLGStyle.inkLabel(blgMonthLabel, step: .heading, bold: true)
        BLGStyle.inkLabel(blgDayLabel, step: .body)
        BLGStyle.accentButton(blgExportButton, title: "Export CSV")
        blgHero.image = UIImage(named: "blg_TwistHero")
        blgHero.isAccessibilityElement = false
        blgTableView.dataSource = self
        blgTableView.delegate = self
        blgTableView.rowHeight = 76
        blgTableView.backgroundColor = .clear
        blgTableView.register(BLGEntryCell.self, forCellReuseIdentifier: "BLGStatementLineCell")
        blgEmptyBoard.blg_apply(
            image: "blg_EmptyLog",
            title: "Blank statement",
            body: "Nothing has been posted as eaten on this day.",
            action: "Lookup a product"
        )
        blgEmptyBoard.onAction = { [weak self] in
            self?.blg_drawer?.blg_open(.lookup)
        }
        bind()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.refresh.send(())
    }

    private func bind() {
        viewModel.$lines
            .combineLatest(viewModel.$dayKey, viewModel.$monthTitle)
            .receive(on: RunLoop.main)
            .sink { [weak self] lines, day, month in
                self?.blgMonthLabel.text = "Month " + month
                self?.blgDayLabel.text = day
                self?.blgEmptyBoard.isHidden = lines.isEmpty == false
                self?.blgTableView.isHidden = lines.isEmpty
                self?.blgTableView.reloadData()
            }
            .store(in: &bag)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.lines.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BLGStatementLineCell", for: indexPath) as? BLGEntryCell ?? BLGEntryCell(style: .default, reuseIdentifier: "BLGStatementLineCell")
        let line = viewModel.lines[indexPath.row]
        cell.blg_bind(line: line, highlight: viewModel.highlightedID == line.id)
        return cell
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let line = viewModel.lines[indexPath.row]
        let action = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, done in
            self?.blg_confirmDelete(line)
            done(true)
        }
        return UISwipeActionsConfiguration(actions: [action])
    }

    @IBAction func blg_prevDay(_ sender: Any) {
        viewModel.shiftDay.send(-1)
    }

    @IBAction func blg_nextDay(_ sender: Any) {
        viewModel.shiftDay.send(1)
    }

    @IBAction func blg_export(_ sender: Any) {
        viewModel.export.send(())
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("BiteLedger-statement.csv")
        do {
            try viewModel.csvText.data(using: .utf8)?.write(to: url)
            let sheet = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            sheet.popoverPresentationController?.sourceView = blgExportButton
            present(sheet, animated: true)
        } catch {
            let alert = UIAlertController(title: "Export failed", message: "The CSV folio could not be written.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }

    private func blg_confirmDelete(_ line: BLGLedgerLine) {
        let alert = UIAlertController(title: "Strike this line?", message: line.entry.productName, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.viewModel.delete.send(line.id)
        })
        present(alert, animated: true)
    }
}
