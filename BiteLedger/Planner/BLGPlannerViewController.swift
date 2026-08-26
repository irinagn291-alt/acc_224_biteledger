import Combine
import UIKit

/// Fourteen-day planner. One action converts a plan line to eaten today.
@MainActor
final class BLGPlannerViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var blgHorizonLabel: UILabel!
    @IBOutlet weak var blgTableView: UITableView!
    @IBOutlet weak var blgEmptyBoard: BLGEmptyBoardView!

    private let viewModel = BLGPlannerViewModel()
    private var bag = Set<AnyCancellable>()
    private var keys: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Planner"
        BLGStyle.paper(view)
        BLGStyle.inkLabel(blgHorizonLabel, step: .caption)
        blgHorizonLabel.text = "Next \(BLGPlannerViewModel.horizonDays) days"
        blgTableView.dataSource = self
        blgTableView.delegate = self
        blgTableView.rowHeight = 72
        blgTableView.register(BLGEntryCell.self, forCellReuseIdentifier: "BLGPlanCell")
        blgTableView.backgroundColor = .clear
        blgEmptyBoard.blg_apply(
            image: "blg_EmptyPlan",
            title: "Nothing ruled ahead",
            body: "Plan a folio for a future date when you assign it.",
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
        viewModel.$byDay
            .receive(on: RunLoop.main)
            .sink { [weak self] grouped in
                self?.keys = Array(grouped.keys)
                self?.blgEmptyBoard.isHidden = grouped.isEmpty == false
                self?.blgTableView.isHidden = grouped.isEmpty
                self?.blgTableView.reloadData()
            }
            .store(in: &bag)
    }

    func numberOfSections(in tableView: UITableView) -> Int { keys.count }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.byDay[keys[section]]?.count ?? 0
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        keys[section]
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BLGPlanCell", for: indexPath) as? BLGEntryCell ?? BLGEntryCell(style: .default, reuseIdentifier: "BLGPlanCell")
        if let entry = viewModel.byDay[keys[indexPath.section]]?[indexPath.row] {
            cell.blg_bind(entry: entry, highlight: false)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let entry = viewModel.byDay[keys[indexPath.section]]?[indexPath.row] else { return }
        let alert = UIAlertController(title: "Post as eaten today?", message: entry.productName, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Post", style: .default) { [weak self] _ in
            self?.viewModel.convert.send(entry.id)
        })
        present(alert, animated: true)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let entry = viewModel.byDay[keys[indexPath.section]]?[indexPath.row] else { return nil }
        let action = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, done in
            let alert = UIAlertController(title: "Strike this plan?", message: entry.productName, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
                self?.viewModel.delete.send(entry.id)
            })
            self?.present(alert, animated: true)
            done(true)
        }
        return UISwipeActionsConfiguration(actions: [action])
    }
}
