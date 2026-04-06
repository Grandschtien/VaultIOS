import UIKit
import Nivelir

@MainActor
protocol CategoryEmojiPickerRoutingLogic: Sendable {
    func close()
}

final class CategoryEmojiPickerRouter: CategoryEmojiPickerRoutingLogic {
    private let screenRouter: ScreenNavigator

    weak var viewController: UIViewController?

    init(screenRouter: ScreenNavigator) {
        self.screenRouter = screenRouter
    }

    func close() {
        screenRouter.navigate(from: viewController) { route in
            route.dimiss()
        }
    }
}
