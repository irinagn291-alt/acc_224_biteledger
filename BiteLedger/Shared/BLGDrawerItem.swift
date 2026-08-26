import Foundation

enum BLGDrawerItem: Int, CaseIterable, Sendable {
    case ledger
    case statement
    case lookup
    case scan
    case planner
    case wishlist
    case goals

    var title: String {
        switch self {
        case .ledger: return "Ledger"
        case .statement: return "Statement"
        case .lookup: return "Lookup"
        case .scan: return "Scan"
        case .planner: return "Planner"
        case .wishlist: return "Wishlist"
        case .goals: return "Goals"
        }
    }

    var storyboardID: String {
        switch self {
        case .ledger: return "BLGLedgerViewController"
        case .statement: return "BLGStatementViewController"
        case .lookup: return "BLGLookupViewController"
        case .scan: return "BLGScanViewController"
        case .planner: return "BLGPlannerViewController"
        case .wishlist: return "BLGWishlistViewController"
        case .goals: return "BLGGoalsViewController"
        }
    }
}
