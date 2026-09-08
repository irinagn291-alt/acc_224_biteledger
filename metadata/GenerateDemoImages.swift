import CoreGraphics
import CoreImage
import Foundation
import ImageIO
import UniformTypeIdentifiers
import Vision

let code = "7394376616037"
let outDir = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : FileManager.default.currentDirectoryPath)

guard let qr = CIFilter(name: "CIQRCodeGenerator") else {
    fputs("CIQRCodeGenerator missing\n", stderr)
    exit(1)
}
qr.setValue(Data(code.utf8), forKey: "inputMessage")
qr.setValue("M", forKey: "inputCorrectionLevel")
guard let raw = qr.outputImage,
      let color = CIFilter(name: "CIFalseColor")
else {
    fputs("QR output missing\n", stderr)
    exit(1)
}
color.setValue(raw, forKey: kCIInputImageKey)
color.setValue(CIColor.black, forKey: "inputColor0")
color.setValue(CIColor.white, forKey: "inputColor1")
guard let tinted = color.outputImage else {
    fputs("QR tint missing\n", stderr)
    exit(1)
}

let module = 36
let quietModules = 6
let scale = CGFloat(module)
let scaled = tinted.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
let colorSpace = CGColorSpaceCreateDeviceRGB()
let context = CIContext(options: [.workingColorSpace: colorSpace, .outputColorSpace: colorSpace])
guard let qrCG = context.createCGImage(scaled, from: scaled.extent, format: .RGBA8, colorSpace: colorSpace) else {
    fputs("QR raster failed extent=\(scaled.extent)\n", stderr)
    exit(1)
}

let pad = module * quietModules
let side = qrCG.width + pad * 2
let colorSpace = CGColorSpaceCreateDeviceRGB()
guard let canvas = CGContext(
    data: nil,
    width: side,
    height: side,
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    fputs("canvas failed\n", stderr)
    exit(1)
}
canvas.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
canvas.fill(CGRect(x: 0, y: 0, width: side, height: side))
canvas.interpolationQuality = .none
canvas.draw(qrCG, in: CGRect(x: pad, y: pad, width: qrCG.width, height: qrCG.height))
guard let cg = canvas.makeImage() else {
    fputs("canvas image failed\n", stderr)
    exit(1)
}

let request = VNDetectBarcodesRequest()
request.symbologies = [.qr]
let handler = VNImageRequestHandler(cgImage: cg, options: [:])
do {
    try handler.perform([request])
} catch {
    fputs("Vision failed: \(error)\n", stderr)
    exit(1)
}
guard let payload = request.results?.first?.payloadStringValue else {
    fputs("Vision did not decode the generated QR\n", stderr)
    exit(1)
}
guard payload == code else {
    fputs("QR payload mismatch: \(payload)\n", stderr)
    exit(1)
}

let url = outDir.appendingPathComponent("demo-qr-oat-milk.png")
guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
    fputs("dest failed\n", stderr)
    exit(1)
}
CGImageDestinationAddImage(dest, cg, nil)
if !CGImageDestinationFinalize(dest) {
    fputs("finalize failed\n", stderr)
    exit(1)
}
print("verified \(payload) -> \(url.path) \(cg.width)x\(cg.height)")
