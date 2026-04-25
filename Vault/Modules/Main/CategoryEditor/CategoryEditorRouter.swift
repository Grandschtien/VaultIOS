import UIKit
import Nivelir

@MainActor
protocol CategoryEditorRoutingLogic: Sendable {
    func close()
    func openEmojiPicker(selectedEmoji: String, output: CategoryEmojiPickerOutput)
    func openColorPicker(selectedHex: String)
    func openSubscription(
        currentTier: String,
        output: SubscriptionOutput
    )
    func presentError(with text: String)
}

final class CategoryEditorRouter: NSObject, CategoryEditorRoutingLogic {
    private let screenRouter: ScreenNavigator
    private let context: MainFlowContext
    private let toastPresenter: ToastPresenting
    private let colorProvider: CategoryColorProviding

    weak var viewController: UIViewController?
    weak var systemPickerOutput: CategoryEditorSystemPickerOutput?

    init(
        screenRouter: ScreenNavigator,
        context: MainFlowContext,
        toastPresenter: ToastPresenting,
        colorProvider: CategoryColorProviding
    ) {
        self.screenRouter = screenRouter
        self.context = context
        self.toastPresenter = toastPresenter
        self.colorProvider = colorProvider
    }

    func close() {
        if let navigationController = viewController?.navigationController,
           navigationController.viewControllers.count > 1 {
            screenRouter.navigate(from: navigationController) { route in
                route.pop()
            }
            return
        }

        screenRouter.navigate(from: viewController) { route in
            route.dimiss()
        }
    }

    func openEmojiPicker(
        selectedEmoji: String,
        output: CategoryEmojiPickerOutput
    ) {
        guard let viewController else {
            return
        }

        screenRouter.navigate(from: viewController) { route in
            route
                .present(
                    CategoryEmojiPickerFactory(
                        selectedEmoji: selectedEmoji,
                        output: output
                    )
                )
        }
    }

    func openColorPicker(selectedHex: String) {
        guard let viewController else {
            return
        }

        let controller = UIColorPickerViewController()
        controller.supportsAlpha = false
        controller.selectedColor = colorProvider.color(for: selectedHex)
        controller.delegate = self
        viewController.present(controller, animated: true)
    }

    func openSubscription(
        currentTier: String,
        output: SubscriptionOutput
    ) {
        guard let viewController else {
            return
        }

        screenRouter.navigate(from: viewController) { route in
            route.present(
                SubscriptionFactory(
                    currentTier: currentTier,
                    output: output
                )
                .withModalPresentationStyle(.pageSheet)
            )
        }
    }

    func presentError(with text: String) {
        toastPresenter.present(state: .error, title: text)
    }
}

extension CategoryEditorRouter: UIColorPickerViewControllerDelegate {
    func colorPickerViewControllerDidSelectColor(
        _ viewController: UIColorPickerViewController
    ) {
        guard let hex = colorProvider.hexString(from: viewController.selectedColor) else {
            return
        }

        Task { [weak systemPickerOutput] in
            await systemPickerOutput?.handleDidSelectCustomColor(hex)
        }
    }
}
