import Combine
import UIKit

/// Slot + date assign. Petty Cash is eaten-only and remaps to Midday when planning.
@MainActor
final class BLGAssignViewController: UIViewController {
    @IBOutlet weak var blgScrollView: UIScrollView!
    @IBOutlet weak var blgSlotStack: UIStackView!
    @IBOutlet weak var blgWhenControl: UISegmentedControl!
    @IBOutlet weak var blgDatePicker: UIDatePicker!
    @IBOutlet weak var blgNoteLabel: UILabel!
    @IBOutlet weak var blgConfirmButton: UIButton!

    var blgProduct: BLGProduct?
    var blgGrams: Double?
    private var viewModel: BLGAssignViewModel?
    private var bag = Set<AnyCancellable>()
    private let keyboard = BLGKeyboardWatch()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Post entry"
        BLGStyle.paper(view)
        guard let product = blgProduct, let grams = blgGrams else { return }
        let vm = BLGAssignViewModel(product: product, grams: grams)
        viewModel = vm
        blgWhenControl.setTitle("Eaten today", forSegmentAt: 0)
        blgWhenControl.setTitle("Plan ahead", forSegmentAt: 1)
        blgWhenControl.selectedSegmentIndex = 0
        blgDatePicker.datePickerMode = .date
        blgDatePicker.preferredDatePickerStyle = .compact
        blgDatePicker.minimumDate = Calendar.current.startOfDay(for: Date())
        blgDatePicker.isHidden = true
        BLGStyle.mutedLabel(blgNoteLabel, step: .caption)
        BLGStyle.accentButton(blgConfirmButton, title: "Post to ledger")
        keyboard.attach(scrollView: blgScrollView, host: view)
        blg_rebuildSlots(vm)
        bind(vm)
    }

    private func bind(_ vm: BLGAssignViewModel) {
        vm.$slot.combineLatest(vm.$eaten, vm.$dayKey)
            .receive(on: RunLoop.main)
            .sink { [weak self] _, eaten, day in
                guard let self else { return }
                self.blg_rebuildSlots(vm)
                self.blgDatePicker.isHidden = eaten
                self.blgWhenControl.selectedSegmentIndex = eaten ? 0 : 1
                self.blgNoteLabel.text = eaten
                    ? "Posting to \(day) as eaten."
                    : "Planning for \(day). Petty Cash remaps to Midday."
            }
            .store(in: &bag)
        vm.$isSaving
            .receive(on: RunLoop.main)
            .sink { [weak self] busy in
                self?.blgConfirmButton.isEnabled = !busy
            }
            .store(in: &bag)
        vm.$posted
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] entry in
                self?.blg_finish(entry)
            }
            .store(in: &bag)
    }

    private func blg_rebuildSlots(_ vm: BLGAssignViewModel) {
        blgSlotStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for slot in vm.availableSlots {
            let button = UIButton(type: .system)
            if slot == vm.slot {
                BLGStyle.accentButton(button, title: slot.label)
            } else {
                BLGStyle.ghostButton(button, title: slot.label)
            }
            button.tag = BLGSlot.allCases.firstIndex(of: slot) ?? 0
            button.addTarget(self, action: #selector(blg_pickSlot(_:)), for: .touchUpInside)
            button.accessibilityLabel = slot.label
            blgSlotStack.addArrangedSubview(button)
        }
    }

    @objc private func blg_pickSlot(_ sender: UIButton) {
        let slot = BLGSlot.allCases[sender.tag]
        viewModel?.selectSlot.send(slot)
    }

    @IBAction func blg_whenChanged(_ sender: UISegmentedControl) {
        let eaten = sender.selectedSegmentIndex == 0
        viewModel?.selectEaten.send(eaten)
        if eaten == false {
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
            blgDatePicker.date = tomorrow
            viewModel?.selectDate.send(tomorrow)
        }
    }

    @IBAction func blg_dateChanged(_ sender: UIDatePicker) {
        viewModel?.selectDate.send(sender.date)
    }

    @IBAction func blg_confirm(_ sender: Any) {
        viewModel?.confirm.send(())
    }

    private func blg_finish(_ entry: BLGEntry) {
        if let drawer = blg_drawer {
            drawer.blg_open(entry.dayKey == BLGDayKey.make(from: Date()) ? .ledger : .planner)
        } else {
            navigationController?.popToRootViewController(animated: true)
        }
    }
}
