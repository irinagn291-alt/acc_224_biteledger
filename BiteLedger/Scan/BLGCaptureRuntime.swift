import AVFoundation
import Foundation

/// Capture session confined to `queue`. Unchecked Sendable because that queue is the only mutator.
final class BLGCaptureRuntime: @unchecked Sendable {
    let session = AVCaptureSession()
    let queue = DispatchQueue(label: "blg.scan.session")
    var output: AVCaptureMetadataOutput?

    func start() {
        queue.async { [session] in
            if session.isRunning == false {
                session.startRunning()
            }
        }
    }

    func stop() {
        queue.async { [session] in
            if session.isRunning {
                session.stopRunning()
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
        queue.async {
            self.output?.setMetadataObjectsDelegate(delegate, queue: DispatchQueue.main)
        }
    }
}
