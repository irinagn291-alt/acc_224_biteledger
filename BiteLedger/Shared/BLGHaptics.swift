import UIKit

@MainActor
enum BLGHaptics {
    static func commit() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
