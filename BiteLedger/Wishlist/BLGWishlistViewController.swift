import Combine
import UIKit

/// Wish folio. Promote a row into Detail for assign to log or plan.
@MainActor
final class BLGWishlistViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var blgTableView: UITableView!
    @IBOutlet weak var blgEmptyBoard: BLGEmptyBoardView!

    private let viewModel = BLGWishlistViewModel()
    private var bag = Set<AnyCancellable>()
    private var pendingProduct: BLGProduct?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Wishlist"
        BLGStyle.paper(view)
        blgTableView.dataSource = self
        blgTableView.delegate = self
        blgTableView.rowHeight = 68
        blgTableView.register(BLGProductCell.self, forCellReuseIdentifier: "BLGWishCell")
        blgTableView.backgroundColor = .clear
        blgEmptyBoard.blg_apply(
            image: "blg_EmptyWish",
            title: "The basket is empty",
            body: "Save a folio from a product page when you mean to buy it.",
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
        viewModel.$items
            .receive(on: RunLoop.main)
            .sink { [weak self] items in
                self?.blgEmptyBoard.isHidden = items.isEmpty == false
                self?.blgTableView.isHidden = items.isEmpty
                self?.blgTableView.reloadData()
            }
            .store(in: &bag)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BLGWishCell", for: indexPath) as? BLGProductCell ?? BLGProductCell(style: .default, reuseIdentifier: "BLGWishCell")
        cell.blg_bind(viewModel.items[indexPath.row].asProduct)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        pendingProduct = viewModel.items[indexPath.row].asProduct
        performSegue(withIdentifier: "blg_showProduct", sender: nil)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let item = viewModel.items[indexPath.row]
        let action = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, done in
            let alert = UIAlertController(title: "Remove this wish?", message: item.productName, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
                self?.viewModel.delete.send(item.barcode)
            })
            self?.present(alert, animated: true)
            done(true)
        }
        return UISwipeActionsConfiguration(actions: [action])
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "blg_showProduct", let dest = segue.destination as? BLGProductViewController {
            dest.blgProduct = pendingProduct
        }
    }
}
