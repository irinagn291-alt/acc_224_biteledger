import Combine
import UIKit

/// First scene. Opens the store, then routes to onboarding or the drawer.
@MainActor
final class BLGLaunchViewController: UIViewController {
    @IBOutlet weak var blgSplashView: UIImageView?
    private var bag = Set<AnyCancellable>()
    private var routed = false
    private var readyToRoute = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = BLGPalette.background
        blgSplashView?.image = UIImage(named: "blg_Splash")
        blgSplashView?.contentMode = .scaleAspectFill
        blgSplashView?.isAccessibilityElement = false
        BLGServices.account.start()
            .receive(on: RunLoop.main)
            .sink { [weak self] completion in
                if case .failure = completion {
                    self?.readyToRoute = true
                    self?.blg_routeIfVisible()
                }
            } receiveValue: { [weak self] _ in
                self?.readyToRoute = true
                self?.blg_routeIfVisible()
            }
            .store(in: &bag)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        blg_routeIfVisible()
    }

    private func blg_routeIfVisible() {
        guard readyToRoute, routed == false, view.window != nil else { return }
        routed = true
        if BLGServices.account.isOnboarded {
            performSegue(withIdentifier: "blg_presentDrawer", sender: nil)
        } else {
            performSegue(withIdentifier: "blg_presentOnboarding", sender: nil)
        }
    }
}
