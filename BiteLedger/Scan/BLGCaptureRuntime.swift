import AVFoundation
import Foundation
import UIKit
import Vision
import VisionKit

/// Capture session confined to `queue`. Unchecked Sendable because that queue is the only mutator.
final class BLGCaptureRuntime: @unchecked Sendable {
    let session = AVCaptureSession()
    let queue = DispatchQueue(label: "blg.scan.session")
    var output: AVCaptureMetadataOutput?
    private var pendingDelegate: AVCaptureMetadataOutputObjectsDelegate?

    func start() {
        queue.async {
            if self.session.isRunning == false {
                self.session.startRunning()
            }
        }
    }

    func stop() {
        queue.async {
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }

    func configureIfNeeded() {
        if session.inputs.isEmpty == false { return }
        session.beginConfiguration()
        session.sessionPreset = .high
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input)
        else {
            session.commitConfiguration()
            return
        }
        session.addInput(input)
        let fresh = AVCaptureMetadataOutput()
        if session.canAddOutput(fresh) {
            session.addOutput(fresh)
            let wanted: [AVMetadataObject.ObjectType] = [.ean8, .ean13, .upce, .qr]
            fresh.metadataObjectTypes = wanted.filter { fresh.availableMetadataObjectTypes.contains($0) }
            output = fresh
        }
        session.commitConfiguration()
    }

    func setDelegate(_ delegate: AVCaptureMetadataOutputObjectsDelegate) {
        pendingDelegate = delegate
        queue.async {
            self.output?.setMetadataObjectsDelegate(self.pendingDelegate, queue: DispatchQueue.main)
        }
    }
}

/// Same live scanner as the Food apps: VisionKit DataScanner, QR included, fire on didAdd.
@MainActor
final class BLGVisionCatcher: NSObject, DataScannerViewControllerDelegate {
    var onCode: ((String) -> Void)?
    private(set) var scanner: DataScannerViewController?

    static var isUsable: Bool {
        DataScannerViewController.isSupported && DataScannerViewController.isAvailable
    }

    func embed(in host: UIView, parent: UIViewController) {
        guard scanner == nil, Self.isUsable else { return }
        let symbologies: [VNBarcodeSymbology] = [
            .ean13, .ean8, .upce, .code128, .code39, .qr, .dataMatrix, .pdf417
        ]
        let controller = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: symbologies)],
            qualityLevel: .accurate,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: true,
            isHighlightingEnabled: true
        )
        controller.delegate = self
        parent.addChild(controller)
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        host.addSubview(controller.view)
        NSLayoutConstraint.activate([
            controller.view.topAnchor.constraint(equalTo: host.topAnchor),
            controller.view.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            controller.view.trailingAnchor.constraint(equalTo: host.trailingAnchor),
            controller.view.bottomAnchor.constraint(equalTo: host.bottomAnchor)
        ])
        controller.didMove(toParent: parent)
        scanner = controller
    }

    func start() {
        guard let scanner, scanner.isScanning == false else { return }
        try? scanner.startScanning()
    }

    func stop() {
        scanner?.stopScanning()
    }

    func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
        blg_emit(item)
    }

    func dataScanner(
        _ dataScanner: DataScannerViewController,
        didAdd addedItems: [RecognizedItem],
        allItems: [RecognizedItem]
    ) {
        for item in addedItems {
            blg_emit(item)
        }
    }

    private func blg_emit(_ item: RecognizedItem) {
        guard case .barcode(let barcode) = item,
              let payload = barcode.payloadStringValue,
              payload.isEmpty == false
        else { return }
        onCode?(payload)
    }
}
