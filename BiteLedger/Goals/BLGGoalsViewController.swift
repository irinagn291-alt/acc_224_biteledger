import Combine
import UIKit

/// Daily targets, onboarding replay, confirmed reset and the contact link.
@MainActor
final class BLGGoalsViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var blgScrollView: UIScrollView!
    @IBOutlet weak var blgKcalField: UITextField!
    @IBOutlet weak var blgProteinField: UITextField!
    @IBOutlet weak var blgCarbsField: UITextField!
    @IBOutlet weak var blgFatField: UITextField!
    @IBOutlet weak var blgSaveButton: UIButton!
    @IBOutlet weak var blgOnboardButton: UIButton!
    @IBOutlet weak var blgResetButton: UIButton!
    @IBOutlet weak var blgContactButton: UIButton!
    @IBOutlet weak var blgNoticeLabel: UILabel!

    private let viewModel = BLGGoalsViewModel()
    private var bag = Set<AnyCancellable>()
    private let keyboard = BLGKeyboardWatch()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Goals"
        BLGStyle.paper(view)
        [blgKcalField, blgProteinField, blgCarbsField, blgFatField].compactMap { $0 }.forEach { field in
            BLGStyle.ledgerField(field)
            field.keyboardType = .decimalPad
            field.delegate = self
        }
        blg_caption("Energy kcal", above: blgKcalField)
        blg_caption("Protein g", above: blgProteinField)
        blg_caption("Carbs g", above: blgCarbsField)
        blg_caption("Fat g", above: blgFatField)
        blgKcalField.accessibilityLabel = "Energy target"
        blgProteinField.accessibilityLabel = "Protein target"
        blgCarbsField.accessibilityLabel = "Carbohydrate target"
        blgFatField.accessibilityLabel = "Fat target"
        BLGStyle.accentButton(blgSaveButton, title: "Save targets")
        BLGStyle.ghostButton(blgOnboardButton, title: "Re-run onboarding")
        BLGStyle.ghostButton(blgResetButton, title: "Reset all data")
        BLGStyle.ghostButton(blgContactButton, title: "Contact BiteLedger")
        BLGStyle.mutedLabel(blgNoticeLabel, step: .caption)
        keyboard.attach(scrollView: blgScrollView, host: view)
        bind()
        viewModel.reload.send(())
    }

    private func bind() {
        viewModel.$kcalText.receive(on: RunLoop.main).sink { [weak self] in self?.blgKcalField.text = $0 }.store(in: &bag)
        viewModel.$proteinText.receive(on: RunLoop.main).sink { [weak self] in self?.blgProteinField.text = $0 }.store(in: &bag)
        viewModel.$carbsText.receive(on: RunLoop.main).sink { [weak self] in self?.blgCarbsField.text = $0 }.store(in: &bag)
        viewModel.$fatText.receive(on: RunLoop.main).sink { [weak self] in self?.blgFatField.text = $0 }.store(in: &bag)
        viewModel.$notice.receive(on: RunLoop.main).sink { [weak self] in self?.blgNoticeLabel.text = $0 }.store(in: &bag)
        viewModel.$isSaving.receive(on: RunLoop.main).sink { [weak self] busy in
            self?.blgSaveButton.isEnabled = !busy
        }.store(in: &bag)
    }

    private func blg_caption(_ title: String, above field: UITextField?) {
        guard let field, let stack = field.superview as? UIStackView,
              let idx = stack.arrangedSubviews.firstIndex(of: field) else { return }
        let label = UILabel()
        label.text = title
        BLGStyle.inkLabel(label, step: .caption)
        stack.insertArrangedSubview(label, at: idx)
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.isEmpty { return true }
        let allowed = CharacterSet.decimalDigits.union(CharacterSet(charactersIn: BLGFormatters.grams.decimalSeparator ?? "."))
        return string.unicodeScalars.allSatisfy { allowed.contains($0) }
    }

    @IBAction func blg_save(_ sender: Any) {
        viewModel.kcalText = blgKcalField.text ?? ""
        viewModel.proteinText = blgProteinField.text ?? ""
        viewModel.carbsText = blgCarbsField.text ?? ""
        viewModel.fatText = blgFatField.text ?? ""
        viewModel.save.send(())
    }

    @IBAction func blg_onboard(_ sender: Any) {
        BLGServices.account.clearOnboarding()
        performSegue(withIdentifier: "blg_presentOnboarding", sender: nil)
    }

    @IBAction func blg_reset(_ sender: Any) {
        let alert = UIAlertController(
            title: "Wipe the ledger?",
            message: "Entries, plans, wishes and cached products will be struck out. Targets return to defaults.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Reset", style: .destructive) { [weak self] _ in
            self?.viewModel.reset.send(())
        })
        present(alert, animated: true)
    }

    @IBAction func blg_contact(_ sender: Any) {
        WebContentHost.presentContact(from: self)
    }
}
