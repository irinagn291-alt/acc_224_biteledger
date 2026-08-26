import Combine
import UIKit

/// Keeps the focused field visible when the keyboard rises. Invalidated with the cancellable bag.
@MainActor
final class BLGKeyboardWatch {
    private var bag = Set<AnyCancellable>()

    func attach(scrollView: UIScrollView, host: UIView) {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
            .merge(with: NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification))
            .receive(on: RunLoop.main)
            .sink { [weak scrollView, weak host] notification in
                guard let scrollView, let host, let info = notification.userInfo else { return }
                let frame = (info[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect) ?? .zero
                let converted = host.convert(frame, from: nil)
                let overlap = max(0, host.bounds.maxY - converted.minY)
                scrollView.contentInset.bottom = overlap
                scrollView.verticalScrollIndicatorInsets.bottom = overlap
            }
            .store(in: &bag)

        let tap = UITapGestureRecognizer()
        tap.cancelsTouchesInView = false
        tap.addTarget(self, action: #selector(blg_dismiss))
        host.addGestureRecognizer(tap)
    }

    @objc private func blg_dismiss() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
