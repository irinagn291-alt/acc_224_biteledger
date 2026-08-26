import Foundation

/// Composition root. Created once; ViewModels receive `account` rather than opening SQLite themselves.
enum BLGServices {
    static let account: BLGAccountService = {
        let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let directory = folder.appendingPathComponent("BiteLedger", isDirectory: true)
        if FileManager.default.fileExists(atPath: directory.path) == false {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        let path = directory.appendingPathComponent("ledger.sqlite").path
        return BLGAccountService(store: BLGLedgerStore(path: path), catalog: BLGCatalogClient())
    }()
}
