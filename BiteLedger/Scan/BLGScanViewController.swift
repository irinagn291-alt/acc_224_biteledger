import AVFoundation
import Combine
import UIKit

/// Live barcode capture via AVCaptureMetadataOutput, restricted to the ledger-line window.
@MainActor
final class BLGScanViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate, UITextFieldDelegate {
    @IBOutlet weak var blgPreviewHost: UIView!
    @IBOutlet weak var blgOverlayHost: UIView!
    @IBOutlet weak var blgManualField: UITextField!
    @IBOutlet weak var blgLookupButton: UIButton!
    @IBOutlet weak var blgStatusLabel: UILabel!
    @IBOutlet weak var blgPermissionBoard: BLGEmptyBoardView!
    @IBOutlet weak var blgSampleStack: UIStackView!
    @IBOutlet weak var blgSettingsButton: UIButton!

    private let viewModel = BLGScanViewModel()
    private var bag = Set<AnyCancellable>()
    private let capture = BLGCaptureRuntime()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let lineView = BLGScanLineView()
    private var pendingProduct: BLGProduct?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Scan"
        BLGStyle.paper(view)
        BLGStyle.ledgerField(blgManualField)
        blgManualField.keyboardType = .numberPad
        blgManualField.placeholder = "Type a barcode"
        blgManualField.delegate = self
        blgManualField.accessibilityLabel = "Manual barcode"
        BLGStyle.accentButton(blgLookupButton, title: "Post code")
        BLGStyle.ghostButton(blgSettingsButton, title: "Open Settings")
        BLGStyle.mutedLabel(blgStatusLabel, step: .caption)
        blgOverlayHost.addSubview(lineView)
        lineView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            lineView.leadingAnchor.constraint(equalTo: blgOverlayHost.leadingAnchor),
            lineView.trailingAnchor.constraint(equalTo: blgOverlayHost.trailingAnchor),
            lineView.topAnchor.constraint(equalTo: blgOverlayHost.topAnchor),
            lineView.bottomAnchor.constraint(equalTo: blgOverlayHost.bottomAnchor)
        ])
        blg_installSamples()
        bind()
        blg_observeLifecycle()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        blg_evaluatePermission()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = blgPreviewHost.bounds
        blg_updateInterest()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        capture.stop()
    }

    private func bind() {
        viewModel.$permission
            .receive(on: RunLoop.main)
            .sink { [weak self] permission in
                self?.blg_render(permission)
            }
            .store(in: &bag)
        viewModel.$resolve
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                switch state {
                case .idle:
                    self?.blgStatusLabel.text = "Centre a barcode or QR in the window, or tap a shelf row."
                    self?.blgLookupButton.isEnabled = true
                case .loading:
                    self?.blgStatusLabel.text = "Posting the code to the catalogue…"
                    self?.blgLookupButton.isEnabled = false
                case .failed(let message):
                    self?.blgStatusLabel.text = message
                    self?.blgLookupButton.isEnabled = true
                }
            }
            .store(in: &bag)
        viewModel.$product
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] product in
                self?.pendingProduct = product
                self?.performSegue(withIdentifier: "blg_showProduct", sender: nil)
            }
            .store(in: &bag)
    }

    private func blg_render(_ permission: BLGScanPermission) {
        switch permission {
        case .unknown:
            break
        case .ready:
            blgPermissionBoard.isHidden = true
            blgSettingsButton.isHidden = true
            blgSampleStack.isHidden = false
            blg_start()
        case .noDevice:
            blgPermissionBoard.isHidden = false
            blgSettingsButton.isHidden = true
            blgSampleStack.isHidden = false
            blgPermissionBoard.blg_apply(
                image: "blg_EmptySearch",
                title: "No camera on this desk",
                body: "Use a sample shelf code or type a barcode. The ledger still posts.",
                action: "Use oat milk"
            )
            blgPermissionBoard.onAction = { [weak self] in
                self?.viewModel.manual.send("7394376616037")
            }
        case .denied:
            blgPermissionBoard.isHidden = false
            blgSettingsButton.isHidden = false
            blgSampleStack.isHidden = false
            blgPermissionBoard.blg_apply(
                image: "blg_EmptySearch",
                title: "Camera is shut",
                body: "BiteLedger cannot read packets until camera access is allowed in Settings.",
                action: "Open Settings"
            )
            blgPermissionBoard.onAction = { [weak self] in self?.blg_openSettings() }
        case .restricted:
            blgPermissionBoard.isHidden = false
            blgSettingsButton.isHidden = false
            blgSampleStack.isHidden = false
            blgPermissionBoard.blg_apply(
                image: "blg_EmptySearch",
                title: "Camera is restricted",
                body: "Parental or device controls have locked the camera. Use a typed code.",
                action: "Open Settings"
            )
            blgPermissionBoard.onAction = { [weak self] in self?.blg_openSettings() }
        }
    }

    private func blg_evaluatePermission() {
        guard AVCaptureDevice.default(for: .video) != nil else {
            viewModel.blg_setPermission(.noDevice)
            return
        }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            viewModel.blg_setPermission(.ready)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.viewModel.blg_setPermission(granted ? .ready : .denied)
                }
            }
        case .denied:
            viewModel.blg_setPermission(.denied)
        case .restricted:
            viewModel.blg_setPermission(.restricted)
        @unknown default:
            viewModel.blg_setPermission(.denied)
        }
    }

    private func blg_start() {
        capture.queue.async { [capture] in
            capture.configureIfNeeded()
            if capture.session.isRunning == false {
                capture.session.startRunning()
            }
            DispatchQueue.main.async { [weak self] in
                self?.capture.output?.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                self?.blg_attachPreview()
            }
        }
    }

    private func blg_attachPreview() {
        guard previewLayer == nil else {
            blg_updateInterest()
            return
        }
        let layer = AVCaptureVideoPreviewLayer(session: capture.session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = blgPreviewHost.bounds
        blgPreviewHost.layer.insertSublayer(layer, at: 0)
        previewLayer = layer
        blg_updateInterest()
    }

    private func blg_updateInterest() {
        guard let previewLayer, let output = capture.output, previewLayer.connection != nil else { return }
        let inPreview = lineView.convert(lineView.detectionRect, to: blgPreviewHost)
        guard inPreview.width > 8, inPreview.height > 8 else { return }
        output.rectOfInterest = previewLayer.metadataOutputRectConverted(fromLayerRect: inPreview)
    }

    nonisolated func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let first = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let value = first.stringValue
        else { return }
        DispatchQueue.main.async { [weak self] in
            self?.viewModel.decoded.send(value)
        }
    }

    private func blg_installSamples() {
        blgSampleStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let demo = UIButton(type: .system)
        BLGStyle.ghostButton(demo, title: "Show demo QR")
        demo.accessibilityLabel = "Show demo QR for App Review"
        demo.addAction(UIAction { [weak self] _ in
            self?.blg_presentDemoQR()
        }, for: .touchUpInside)
        blgSampleStack.addArrangedSubview(demo)
        for product in BLGShelf.products {
            let button = UIButton(type: .system)
            BLGStyle.ghostButton(button, title: product.name)
            button.accessibilityLabel = "Sample \(product.name)"
            button.addAction(UIAction { [weak self] _ in
                self?.viewModel.manual.send(product.barcode)
            }, for: .touchUpInside)
            blgSampleStack.addArrangedSubview(button)
        }
    }

    private func blg_observeLifecycle() {
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.capture.stop()
            }
            .store(in: &bag)
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                if self?.viewIfLoaded?.window != nil {
                    self?.blg_evaluatePermission()
                }
            }
            .store(in: &bag)
    }

    @IBAction func blg_lookup(_ sender: Any) {
        view.endEditing(true)
        viewModel.manual.send(blgManualField.text ?? "")
    }

    @IBAction func blg_openSettingsTapped(_ sender: Any) {
        blg_openSettings()
    }

    private func blg_openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private func blg_presentDemoQR() {
        let sheet = BLGDemoBarcodeViewController()
        sheet.onPost = { [weak self] in
            self?.viewModel.manual.send(BLGDemoBarcode.code)
        }
        let nav = UINavigationController(rootViewController: sheet)
        present(nav, animated: true)
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.isEmpty { return true }
        return string.unicodeScalars.allSatisfy { CharacterSet.decimalDigits.contains($0) }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "blg_showProduct", let dest = segue.destination as? BLGProductViewController {
            dest.blgProduct = pendingProduct
        }
    }
}
