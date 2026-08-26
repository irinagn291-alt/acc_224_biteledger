import UIKit

/// Custom sliding drawer. No tab bar. Seven destinations replace the navigation root.
@MainActor
final class BLGDrawerContainerController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var blgContentContainer: UIView!
    @IBOutlet weak var blgDimView: UIView!
    @IBOutlet weak var blgMenuView: UIView!
    @IBOutlet weak var blgMenuTableView: UITableView!
    @IBOutlet weak var blgMenuLeading: NSLayoutConstraint!

    private var embeddedNav: UINavigationController?
    private var menuOpen = false
    private var selected = BLGDrawerItem.ledger

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = BLGPalette.background
        blgDimView?.backgroundColor = BLGPalette.ink.withAlphaComponent(0.35)
        blgDimView?.alpha = 0
        blgDimView?.isAccessibilityElement = true
        blgDimView?.accessibilityLabel = "Close menu"
        blgMenuView?.backgroundColor = BLGPalette.surface
        blgMenuTableView?.dataSource = self
        blgMenuTableView?.delegate = self
        blgMenuTableView?.backgroundColor = BLGPalette.surface
        blgMenuTableView?.separatorColor = BLGPalette.muted
        blgMenuTableView?.register(UITableViewCell.self, forCellReuseIdentifier: "BLGDrawerCell")
        blgMenuTableView?.rowHeight = BLGSpace.tap + BLGSpace.n(1)
        let tap = UITapGestureRecognizer(target: self, action: #selector(blg_closeMenu))
        blgDimView?.addGestureRecognizer(tap)
        blgMenuLeading?.constant = -260
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        applyReviewScreenIfNeeded()
    }

    private var reviewApplied = false
    private func applyReviewScreenIfNeeded() {
        guard reviewApplied == false else { return }
        reviewApplied = true
        let args = ProcessInfo.processInfo.arguments
        guard let index = args.firstIndex(of: "-ReviewScreen"), index + 1 < args.count else { return }
        switch args[index + 1] {
        case "log": blg_open(.statement)
        case "goals": blg_open(.goals)
        default: break
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "blg_embedNav", let nav = segue.destination as? UINavigationController {
            embeddedNav = nav
            nav.navigationBar.prefersLargeTitles = false
            nav.navigationBar.titleTextAttributes = [
                .font: BLGTypography.bold(.heading),
                .foregroundColor: BLGPalette.ink
            ]
            nav.viewControllers.first.map { blg_decorate($0) }
        }
    }

    func blg_open(_ item: BLGDrawerItem) {
        selected = item
        guard let storyboard else { return }
        let vc = storyboard.instantiateViewController(withIdentifier: item.storyboardID)
        vc.title = item.title
        blg_decorate(vc)
        embeddedNav?.setViewControllers([vc], animated: false)
        blg_closeMenu()
        blgMenuTableView?.reloadData()
    }

    func blg_toggleMenu() {
        menuOpen ? blg_closeMenu() : blg_openMenu()
    }

    @objc func blg_closeMenu() {
        guard menuOpen else { return }
        menuOpen = false
        blgMenuLeading?.constant = -260
        BLGMotion.animate { [weak self] in
            self?.blgDimView?.alpha = 0
            self?.view.layoutIfNeeded()
        }
    }

    private func blg_openMenu() {
        menuOpen = true
        blgMenuLeading?.constant = 0
        BLGMotion.animate { [weak self] in
            self?.blgDimView?.alpha = 1
            self?.view.layoutIfNeeded()
        }
    }

    private func blg_decorate(_ viewController: UIViewController) {
        let button = UIButton(type: .system)
        button.frame = CGRect(x: 0, y: 0, width: BLGSpace.tap, height: BLGSpace.tap)
        button.accessibilityLabel = "Open ledger menu"
        if let face = UIImage(named: "blg_ControlFace") {
            button.setImage(face.withRenderingMode(.alwaysOriginal), for: .normal)
            button.imageView?.contentMode = .scaleAspectFit
        } else {
            button.setTitle("Menu", for: .normal)
        }
        button.addTarget(self, action: #selector(blg_hamburger), for: .touchUpInside)
        viewController.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: button)
        viewController.navigationItem.leftBarButtonItem?.accessibilityLabel = "Open ledger menu"
    }

    @objc private func blg_hamburger() {
        blg_toggleMenu()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        BLGDrawerItem.allCases.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BLGDrawerCell", for: indexPath)
        let item = BLGDrawerItem.allCases[indexPath.row]
        var config = cell.defaultContentConfiguration()
        config.text = item.title
        config.textProperties.font = BLGTypography.font(.body)
        config.textProperties.color = item == selected ? BLGPalette.accent : BLGPalette.ink
        cell.contentConfiguration = config
        cell.backgroundColor = BLGPalette.surface
        cell.accessibilityLabel = item.title
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        blg_open(BLGDrawerItem.allCases[indexPath.row])
    }
}

extension UIViewController {
    var blg_drawer: BLGDrawerContainerController? {
        var current: UIViewController? = parent
        while let node = current {
            if let drawer = node as? BLGDrawerContainerController {
                return drawer
            }
            current = node.parent
        }
        return nil
    }
}
