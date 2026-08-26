import Combine
import UIKit

/// Four-page onboarding. Skip still writes sensible targets.
@MainActor
final class BLGOnboardingViewController: UIViewController {
    @IBOutlet weak var blgScrollView: UIScrollView!
    @IBOutlet weak var blgImageView: UIImageView!
    @IBOutlet weak var blgTitleLabel: UILabel!
    @IBOutlet weak var blgBodyLabel: UILabel!
    @IBOutlet weak var blgPageControl: UIPageControl!
    @IBOutlet weak var blgSkipButton: UIButton!
    @IBOutlet weak var blgNextButton: UIButton!
    @IBOutlet weak var blgTargetsStack: UIStackView!
    @IBOutlet weak var blgKcalField: UITextField!
    @IBOutlet weak var blgProteinField: UITextField!
    @IBOutlet weak var blgCarbsField: UITextField!
    @IBOutlet weak var blgFatField: UITextField!

    private let viewModel = BLGOnboardingViewModel()
    private var bag = Set<AnyCancellable>()
    private let keyboard = BLGKeyboardWatch()

    override func viewDidLoad() {
        super.viewDidLoad()
        BLGStyle.paper(view)
        blgImageView.isAccessibilityElement = false
        [blgTitleLabel, blgBodyLabel].forEach { BLGStyle.inkLabel($0, step: $0 == blgTitleLabel ? .title : .body, bold: $0 == blgTitleLabel) }
        BLGStyle.ghostButton(blgSkipButton, title: "Skip with defaults")
        BLGStyle.accentButton(blgNextButton, title: "Next")
        blgPageControl.numberOfPages = viewModel.pageCount
        blgPageControl.currentPageIndicatorTintColor = BLGPalette.accent
        blgPageControl.pageIndicatorTintColor = BLGPalette.muted
        blgPageControl.isUserInteractionEnabled = false
        [blgKcalField, blgProteinField, blgCarbsField, blgFatField].forEach { field in
            BLGStyle.ledgerField(field)
            field.keyboardType = .decimalPad
            field.delegate = self
        }
        keyboard.attach(scrollView: blgScrollView, host: view)
        bind()
        render()
    }

    private func bind() {
        viewModel.$page
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.render() }
            .store(in: &bag)
        viewModel.$didFinish
            .filter { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.performSegue(withIdentifier: "blg_presentDrawer", sender: nil)
            }
            .store(in: &bag)
        viewModel.$isSaving
            .receive(on: RunLoop.main)
            .sink { [weak self] busy in
                self?.blgNextButton.isEnabled = !busy
                self?.blgSkipButton.isEnabled = !busy
            }
            .store(in: &bag)
    }

    private func render() {
        let page = viewModel.page
        blgPageControl.currentPage = page
        let images = ["blg_Onboarding1", "blg_Onboarding2", "blg_Onboarding3", "blg_Onboarding3"]
        blgImageView.image = UIImage(named: images[page])
        switch page {
        case 0:
            blgTitleLabel.text = "Your intake, double-entry."
            blgBodyLabel.text = "BiteLedger posts every bite as a debit against the day's energy budget."
        case 1:
            blgTitleLabel.text = "Lookup or scan."
            blgBodyLabel.text = "Search the public Open Food Facts catalogue, or rule a barcode across the ledger line."
        case 2:
            blgTitleLabel.text = "Four columns."
            blgBodyLabel.text = "Opening Entry, Midday Entry, Closing Entry, and Petty Cash for snacks eaten today."
        default:
            blgTitleLabel.text = "Rule your daily targets."
            blgBodyLabel.text = "Set energy and macros. You can rewrite them later from Goals."
        }
        blgTargetsStack.isHidden = page != 3
        blgKcalField.text = viewModel.kcalText
        blgProteinField.text = viewModel.proteinText
        blgCarbsField.text = viewModel.carbsText
        blgFatField.text = viewModel.fatText
        blgNextButton.setTitle(page == 3 ? "Open the ledger" : "Next", for: .normal)
    }

    @IBAction func blg_skip(_ sender: Any) {
        viewModel.skip.send(())
    }

    @IBAction func blg_next(_ sender: Any) {
        if viewModel.page == 3 {
            viewModel.kcalText = blgKcalField.text ?? ""
            viewModel.proteinText = blgProteinField.text ?? ""
            viewModel.carbsText = blgCarbsField.text ?? ""
            viewModel.fatText = blgFatField.text ?? ""
            viewModel.finish.send(())
        } else {
            viewModel.nextPage.send(())
        }
    }
}

extension BLGOnboardingViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.isEmpty { return true }
        let allowed = CharacterSet.decimalDigits.union(CharacterSet(charactersIn: BLGFormatters.grams.decimalSeparator ?? "."))
        return string.unicodeScalars.allSatisfy { allowed.contains($0) }
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        view.endEditing(true)
    }
}
