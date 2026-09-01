import CoreImage
import Foundation
import ImageIO
import UniformTypeIdentifiers

let code = "7394376616037"
let outDir = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : FileManager.default.currentDirectoryPath)

guard let qr = CIFilter(name: "CIQRCodeGenerator") else {
    fputs("CIQRCodeGenerator missing\n", stderr)
    exit(1)
}
qr.setValue(Data(code.utf8), forKey: "inputMessage")
qr.setValue("H", forKey: "inputCorrectionLevel")
guard let raw = qr.outputImage else {
    fputs("QR output missing\n", stderr)
    exit(1)
}

let scale: CGFloat = 28
let scaled = raw.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
let context = CIContext(options: [.useSoftwareRenderer: true])
guard let cg = context.createCGImage(scaled, from: scaled.extent) else {
    fputs("QR raster failed extent=\(scaled.extent)\n", stderr)
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
print(url.path)
