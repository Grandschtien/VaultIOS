import Nivelir
import UIKit

protocol AddExpenseSheetContentSizing: UIView {
    func fittingHeight(for width: CGFloat) -> CGFloat
}

protocol AddExpenseSheetSizingController: HasContentView where ContentView: AddExpenseSheetContentSizing {}

extension AddExpenseSheetSizingController {
    func updatePreferredContentSizeIfNeeded() {
        let width = view.bounds.width
        guard width > .leastNonzeroMagnitude else {
            return
        }

        view.layoutIfNeeded()

        let preferredHeight = ceil(contentView.fittingHeight(for: width))
        let updatedPreferredContentSize = CGSize(
            width: width,
            height: preferredHeight
        )

        guard preferredContentSize != updatedPreferredContentSize else {
            return
        }

        preferredContentSize = updatedPreferredContentSize
        bottomSheet?.invalidateDetents()
    }
}
