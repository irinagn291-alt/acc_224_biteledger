import Combine
import UIKit

/// Name search against Open Food Facts with a local shelf fallback.
@MainActor
final class BLGLookupViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    @IBOutlet weak var blgSearchBar: UISearchBar!
    @IBOutlet weak var blgTableView: UITableView!
    @IBOutlet weak var blgEmptyBoard: BLGEmptyBoardView!
    @IBOutlet weak var blgSpinner: UIActivityIndicatorView!

    private let viewModel = BLGLookupViewModel()
    private var bag = Set<AnyCancellable>()
    private var pendingProduct: BLGProduct?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Lookup"
        BLGStyle.paper(view)
        blgSearchBar.delegate = self
        blgSearchBar.placeholder = "Search the catalogue"
        blgSearchBar.searchTextField.font = BLGTypography.font(.body)
        blgSearchBar.searchTextField.adjustsFontForContentSizeCategory = true
        blgSearchBar.accessibilityLabel = "Search products"
        blgTableView.dataSource = self
        blgTableView.delegate = self
        blgTableView.rowHeight = 68
        blgTableView.keyboardDismissMode = .onDrag
        blgTableView.register(BLGProductCell.self, forCellReuseIdentifier: "BLGProductCell")
        blgTableView.backgroundColor = .clear
        blgSpinner.hidesWhenStopped = true
        blgEmptyBoard.blg_apply(
            image: "blg_EmptySearch",
            title: "No folio on this page",
            body: "Nothing matched. The local shelf is still open below, or try another name.",
            action: "Retry search"
        )
        blgEmptyBoard.onAction = { [weak self] in
            self?.viewModel.retry.send(())
        }
        bind()
    }

    private func bind() {
        viewModel.$products
            .combineLatest(viewModel.$state)
            .receive(on: RunLoop.main)
            .sink { [weak self] products, state in
                guard let self else { return }
                self.blgTableView.reloadData()
                self.blgEmptyBoard.isHidden = state != .empty && state != .failed
                if state == .failed {
                    self.blgEmptyBoard.blg_apply(
                        image: "blg_EmptySearch",
                        title: "The wire failed",
                        body: self.viewModel.notice ?? "Search could not reach Open Food Facts.",
                        action: "Retry"
                    )
                } else if state == .empty {
                    self.blgEmptyBoard.blg_apply(
                        image: "blg_EmptySearch",
                        title: "No folio on this page",
                        body: "Nothing matched that name. Try another term.",
                        action: "Show shelf"
                    )
                    self.blgEmptyBoard.onAction = { [weak self] in
                        self?.blgSearchBar.text = ""
                        self?.viewModel.queryChanged.send("")
                    }
                }
                if state == .loading {
                    self.blgSpinner.startAnimating()
                } else {
                    self.blgSpinner.stopAnimating()
                }
                _ = products
            }
            .store(in: &bag)
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.queryChanged.send(searchText)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.products.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BLGProductCell", for: indexPath) as? BLGProductCell ?? BLGProductCell(style: .default, reuseIdentifier: "BLGProductCell")
        cell.blg_bind(viewModel.products[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        pendingProduct = viewModel.products[indexPath.row]
        performSegue(withIdentifier: "blg_showProduct", sender: nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "blg_showProduct", let dest = segue.destination as? BLGProductViewController {
            dest.blgProduct = pendingProduct
        }
    }
}
