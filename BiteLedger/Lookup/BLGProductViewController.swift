import Combine
import UIKit

/// Product detail: per-100 g macros, grams pad, live totals, assign or wish.
@MainActor
final class BLGProductViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var blgScrollView: UIScrollView!
    @IBOutlet weak var blgBackdrop: UIImageView!
    @IBOutlet weak var blgThumbView: UIImageView!
    @IBOutlet weak var blgNameLabel: UILabel!
    @IBOutlet weak var blgBrandLabel: UILabel!
    @IBOutlet weak var blgEnergyBanner: UILabel!
    @IBOutlet weak var blgKcal100Label: UILabel!
    @IBOutlet weak var blgProtein100Label: UILabel!
    @IBOutlet weak var blgCarbs100Label: UILabel!
    @IBOutlet weak var blgFat100Label: UILabel!
    @IBOutlet weak var blgGramsField: UITextField!
    @IBOutlet weak var blgLiveKcalLabel: UILabel!
    @IBOutlet weak var blgLiveProteinLabel: UILabel!
    @IBOutlet weak var blgLiveCarbsLabel: UILabel!
    @IBOutlet weak var blgLiveFatLabel: UILabel!
    @IBOutlet weak var blgAssignButton: UIButton!
    @IBOutlet weak var blgWishButton: UIButton!
    @IBOutlet weak var blgSuccessMark: UIImageView!

    var blgProduct: BLGProduct?
    private var viewModel: BLGProductViewModel?
    private var bag = Set<AnyCancellable>()
    private var artBag = Set<AnyCancellable>()
    private let keyboard = BLGKeyboardWatch()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Folio"
        BLGStyle.paper(view)
        guard let product = blgProduct else { return }
        let vm = BLGProductViewModel(product: product)
        viewModel = vm
        blgBackdrop.image = UIImage(named: "blg_CardBackdrop")
        blgBackdrop.isAccessibilityElement = false
        blgSuccessMark.image = UIImage(named: "blg_SuccessMark")
        blgSuccessMark.isHidden = true
        blgSuccessMark.isAccessibilityElement = false
        BLGStyle.inkLabel(blgNameLabel, step: .title, bold: true)
        BLGStyle.mutedLabel(blgBrandLabel, step: .body)
        BLGStyle.inkLabel(blgKcal100Label, step: .body)
        BLGStyle.inkLabel(blgProtein100Label, step: .caption)
        BLGStyle.inkLabel(blgCarbs100Label, step: .caption)
        BLGStyle.inkLabel(blgFat100Label, step: .caption)
        [blgLiveKcalLabel, blgLiveProteinLabel, blgLiveCarbsLabel, blgLiveFatLabel].forEach {
            $0?.font = BLGTypography.font(.figure)
            $0?.textColor = BLGPalette.ink
            $0?.adjustsFontForContentSizeCategory = true
        }
        BLGStyle.ledgerField(blgGramsField)
        blgGramsField.keyboardType = .decimalPad
        blgGramsField.delegate = self
        blgGramsField.placeholder = "Grams"
        blgGramsField.accessibilityLabel = "Portion in grams"
        blgEnergyBanner.font = BLGTypography.font(.caption)
        blgEnergyBanner.textColor = BLGPalette.accent
        blgEnergyBanner.numberOfLines = 0
        BLGStyle.accentButton(blgAssignButton, title: "Assign")
        BLGStyle.ghostButton(blgWishButton, title: "Add to wish list")
        keyboard.attach(scrollView: blgScrollView, host: view)
        blg_fill(product)
        bind(vm)
    }

    private func blg_fill(_ product: BLGProduct) {
        blgNameLabel.text = product.name
        blgBrandLabel.text = product.brand.isEmpty ? "Unbranded" : product.brand
        blgKcal100Label.text = "Energy  " + (product.kcal100.map { BLGFormatters.kcalText($0) + " kcal/100 g" } ?? "unknown")
        blgProtein100Label.text = "Protein  " + BLGFormatters.macroText(product.protein100)
        blgCarbs100Label.text = "Carbs  " + BLGFormatters.macroText(product.carbs100)
        blgFat100Label.text = "Fat  " + BLGFormatters.macroText(product.fat100)
        blgEnergyBanner.isHidden = product.kcal100 != nil
        blgEnergyBanner.text = "Energy is unknown for this folio. You can still post grams."
        blgGramsField.text = "100"
        BLGProductArt.apply(to: blgThumbView, imageURL: product.imageURL, bundledAsset: product.bundledAsset, bag: &artBag)
    }

    private func bind(_ vm: BLGProductViewModel) {
        vm.$liveKcal.combineLatest(vm.$liveProtein, vm.$liveCarbs, vm.$liveFat)
            .receive(on: RunLoop.main)
            .sink { [weak self] kcal, protein, carbs, fat in
                self?.blgLiveKcalLabel.text = "This portion  " + BLGFormatters.macroText(kcal) + " kcal"
                self?.blgLiveProteinLabel.text = "P " + BLGFormatters.macroText(protein)
                self?.blgLiveCarbsLabel.text = "C " + BLGFormatters.macroText(carbs)
                self?.blgLiveFatLabel.text = "F " + BLGFormatters.macroText(fat)
            }
            .store(in: &bag)
        vm.$gramsValid
            .combineLatest(vm.$wishBusy)
            .receive(on: RunLoop.main)
            .sink { [weak self] valid, busy in
                self?.blgAssignButton.isEnabled = valid
                self?.blgWishButton.isEnabled = !busy
            }
            .store(in: &bag)
        vm.$wished
            .receive(on: RunLoop.main)
            .sink { [weak self] wished in
                if wished {
                    self?.blgWishButton.setTitle("Already saved", for: .normal)
                    self?.blgWishButton.isEnabled = false
                    self?.blgWishButton.accessibilityLabel = "Already saved"
                }
            }
            .store(in: &bag)
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.isEmpty { return true }
        let separator = BLGFormatters.grams.decimalSeparator ?? "."
        let allowed = CharacterSet.decimalDigits.union(CharacterSet(charactersIn: separator))
        return string.unicodeScalars.allSatisfy { allowed.contains($0) }
    }

    func textFieldDidChangeSelection(_ textField: UITextField) {
        viewModel?.gramsChanged.send(textField.text ?? "")
    }

    @IBAction func blg_assign(_ sender: Any) {
        guard viewModel?.gramsValid == true else { return }
        performSegue(withIdentifier: "blg_showAssign", sender: nil)
    }

    @IBAction func blg_wish(_ sender: Any) {
        viewModel?.addWish.send(())
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "blg_showAssign", let dest = segue.destination as? BLGAssignViewController {
            dest.blgProduct = viewModel?.product
            dest.blgGrams = viewModel?.grams
        }
    }
}
