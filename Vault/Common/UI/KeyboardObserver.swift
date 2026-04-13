import UIKit

fileprivate enum KeyboardObserverConstants {
    static let commandDelayNanoseconds: UInt64 = 250_000_000
    static let visibleInset: CGFloat = 16
}

final class KeyboardObserver {
    private weak var scrollView: UIScrollView?
    private var keyboardWillChangeFrameObserver: NSObjectProtocol?
    private var initialContentInset: UIEdgeInsets = .zero
    private var initialVerticalScrollIndicatorInsets: UIEdgeInsets = .zero
    private var initialIsScrollEnabled = true
    private let dismissTapGestureDelegate = KeyboardDismissTapGestureDelegate()
    private var dismissTapGestureRecognizer: UITapGestureRecognizer?

    deinit {
        detach()
    }

    func attach(to scrollView: UIScrollView) {
        if let currentScrollView = self.scrollView, currentScrollView !== scrollView {
            resetInsets(for: currentScrollView)
            detachDismissTapGesture(from: currentScrollView)
        }

        self.scrollView = scrollView
        initialContentInset = scrollView.contentInset
        initialVerticalScrollIndicatorInsets = scrollView.verticalScrollIndicatorInsets
        initialIsScrollEnabled = scrollView.isScrollEnabled
        attachDismissTapGesture(to: scrollView)
        scrollView.isScrollEnabled = false

        guard keyboardWillChangeFrameObserver == nil else {
            return
        }

        keyboardWillChangeFrameObserver = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillChangeFrameNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleKeyboardWillChangeFrame(notification)
        }
    }

    func detach() {
        if let scrollView {
            resetInsets(for: scrollView)
            detachDismissTapGesture(from: scrollView)
        }

        if let keyboardWillChangeFrameObserver {
            NotificationCenter.default.removeObserver(keyboardWillChangeFrameObserver)
            self.keyboardWillChangeFrameObserver = nil
        }

        scrollView = nil
    }
}

private extension KeyboardObserver {
    @objc
    func handleBackgroundTap() {
        scrollView?.endEditing(true)
    }

    func handleKeyboardWillChangeFrame(_ notification: Notification) {
        guard let scrollView else {
            return
        }

        let keyboardOverlap = resolvedKeyboardOverlap(
            for: scrollView,
            notification: notification
        )
        let contentInset = UIEdgeInsets(
            top: initialContentInset.top,
            left: initialContentInset.left,
            bottom: initialContentInset.bottom + keyboardOverlap,
            right: initialContentInset.right
        )
        let scrollIndicatorInsets = UIEdgeInsets(
            top: initialVerticalScrollIndicatorInsets.top,
            left: initialVerticalScrollIndicatorInsets.left,
            bottom: initialVerticalScrollIndicatorInsets.bottom + keyboardOverlap,
            right: initialVerticalScrollIndicatorInsets.right
        )
        let targetContentOffset = resolvedContentOffsetIfNeeded(
            for: scrollView,
            keyboardOverlap: keyboardOverlap,
            contentInset: contentInset
        )

        let duration = resolvedAnimationDuration(from: notification)
        let options = resolvedAnimationOptions(from: notification)

        if duration <= .zero {
            applyKeyboardLayout(
                to: scrollView,
                keyboardOverlap: keyboardOverlap,
                contentInset: contentInset,
                scrollIndicatorInsets: scrollIndicatorInsets,
                targetContentOffset: targetContentOffset
            )
            return
        }

        UIView.animate(
            withDuration: duration,
            delay: .zero,
            options: options,
            animations: {
                self.applyKeyboardLayout(
                    to: scrollView,
                    keyboardOverlap: keyboardOverlap,
                    contentInset: contentInset,
                    scrollIndicatorInsets: scrollIndicatorInsets,
                    targetContentOffset: targetContentOffset
                )
            }
        )
    }

    func applyKeyboardLayout(
        to scrollView: UIScrollView,
        keyboardOverlap: CGFloat,
        contentInset: UIEdgeInsets,
        scrollIndicatorInsets: UIEdgeInsets,
        targetContentOffset: CGPoint?
    ) {
        scrollView.isScrollEnabled = keyboardOverlap > .zero
        scrollView.contentInset = contentInset
        scrollView.verticalScrollIndicatorInsets = scrollIndicatorInsets

        if let targetContentOffset {
            scrollView.contentOffset = targetContentOffset
        }
    }

    func resolvedKeyboardOverlap(
        for scrollView: UIScrollView,
        notification: Notification
    ) -> CGFloat {
        guard
            let window = scrollView.window,
            let keyboardFrameValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue
        else {
            return .zero
        }

        let keyboardFrame = window.convert(keyboardFrameValue.cgRectValue, from: nil)
        let scrollFrame = scrollView.convert(scrollView.bounds, to: window)
        let intersection = scrollFrame.intersection(keyboardFrame)

        guard !intersection.isNull else {
            return .zero
        }

        return intersection.height
    }

    func resolvedContentOffsetIfNeeded(
        for scrollView: UIScrollView,
        keyboardOverlap: CGFloat,
        contentInset: UIEdgeInsets
    ) -> CGPoint? {
        guard
            keyboardOverlap > .zero,
            let window = scrollView.window,
            let firstResponder = scrollView.activeFirstResponder
        else {
            return nil
        }

        let responderFrame = firstResponder.convert(firstResponder.bounds, to: window)
        let scrollFrame = scrollView.convert(scrollView.bounds, to: window)

        let visibleMinY = scrollFrame.minY + KeyboardObserverConstants.visibleInset
        let visibleMaxY = scrollFrame.maxY - keyboardOverlap - KeyboardObserverConstants.visibleInset

        let deltaY: CGFloat
        if responderFrame.maxY > visibleMaxY {
            deltaY = responderFrame.maxY - visibleMaxY
        } else if responderFrame.minY < visibleMinY {
            deltaY = responderFrame.minY - visibleMinY
        } else {
            return nil
        }

        let adjustedInsets = resolvedAdjustedInsets(
            for: scrollView,
            contentInset: contentInset
        )
        let minimumOffsetY = -adjustedInsets.top
        let maximumOffsetY = max(
            minimumOffsetY,
            scrollView.contentSize.height + adjustedInsets.bottom - scrollView.bounds.height
        )
        let targetOffsetY = min(
            max(scrollView.contentOffset.y + deltaY, minimumOffsetY),
            maximumOffsetY
        )

        return CGPoint(
            x: scrollView.contentOffset.x,
            y: targetOffsetY
        )
    }

    func resolvedAnimationDuration(from notification: Notification) -> TimeInterval {
        notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
    }

    func resolvedAnimationOptions(from notification: Notification) -> UIView.AnimationOptions {
        let curveRawValue = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
            ?? UInt(UIView.AnimationCurve.easeInOut.rawValue)

        return [
            UIView.AnimationOptions(rawValue: curveRawValue << 16),
            .beginFromCurrentState,
            .allowUserInteraction
        ]
    }

    func resetInsets(for scrollView: UIScrollView) {
        scrollView.isScrollEnabled = initialIsScrollEnabled
        scrollView.contentInset = initialContentInset
        scrollView.verticalScrollIndicatorInsets = initialVerticalScrollIndicatorInsets
    }

    func resolvedAdjustedInsets(
        for scrollView: UIScrollView,
        contentInset: UIEdgeInsets
    ) -> UIEdgeInsets {
        UIEdgeInsets(
            top: contentInset.top + scrollView.adjustedContentInset.top - scrollView.contentInset.top,
            left: contentInset.left + scrollView.adjustedContentInset.left - scrollView.contentInset.left,
            bottom: contentInset.bottom + scrollView.adjustedContentInset.bottom - scrollView.contentInset.bottom,
            right: contentInset.right + scrollView.adjustedContentInset.right - scrollView.contentInset.right
        )
    }

    func attachDismissTapGesture(to scrollView: UIScrollView) {
        if dismissTapGestureRecognizer == nil {
            let dismissTapGestureRecognizer = UITapGestureRecognizer(
                target: self,
                action: #selector(handleBackgroundTap)
            )
            dismissTapGestureRecognizer.cancelsTouchesInView = false
            dismissTapGestureRecognizer.delegate = dismissTapGestureDelegate
            self.dismissTapGestureRecognizer = dismissTapGestureRecognizer
        }

        guard
            let dismissTapGestureRecognizer,
            !(scrollView.gestureRecognizers ?? []).contains(dismissTapGestureRecognizer)
        else {
            return
        }

        scrollView.addGestureRecognizer(dismissTapGestureRecognizer)
    }

    func detachDismissTapGesture(from scrollView: UIScrollView) {
        guard let dismissTapGestureRecognizer else {
            return
        }

        scrollView.removeGestureRecognizer(dismissTapGestureRecognizer)
    }
}

extension UIView {
    func executeAfterDismissingKeyboard(_ command: Command) {
        let firstResponder = window?.activeFirstResponder ?? activeFirstResponder

        guard firstResponder != nil else {
            command.execute()
            return
        }

        endEditing(true)

        Task {
            try? await Task.sleep(nanoseconds: KeyboardObserverConstants.commandDelayNanoseconds)
            command.execute()
        }
    }
}

private extension UIView {
    var activeFirstResponder: UIView? {
        if isFirstResponder {
            return self
        }

        for subview in subviews {
            if let activeFirstResponder = subview.activeFirstResponder {
                return activeFirstResponder
            }
        }

        return nil
    }
}

private final class KeyboardDismissTapGestureDelegate: NSObject, UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive touch: UITouch
    ) -> Bool {
        guard let touchedView = touch.view else {
            return true
        }

        return !touchedView.isDescendantOfControl
            && !touchedView.isDescendantOfTextView
            && !touchedView.isDescendantOfTableViewCell
            && !touchedView.isDescendantOfCollectionViewCell
    }
}

private extension UIView {
    var isDescendantOfControl: Bool {
        sequence(first: self, next: { $0.superview }).contains { $0 is UIControl }
    }

    var isDescendantOfTextView: Bool {
        sequence(first: self, next: { $0.superview }).contains { $0 is UITextView }
    }

    var isDescendantOfTableViewCell: Bool {
        sequence(first: self, next: { $0.superview }).contains { $0 is UITableViewCell }
    }

    var isDescendantOfCollectionViewCell: Bool {
        sequence(first: self, next: { $0.superview }).contains { $0 is UICollectionViewCell }
    }
}
