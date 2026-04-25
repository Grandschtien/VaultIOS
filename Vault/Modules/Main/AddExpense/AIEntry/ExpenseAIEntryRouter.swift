import UIKit
import Nivelir

protocol ExpenseAIEntryNoExpenseAlertOutput: AnyObject, Sendable {
    func handleTapAddManually() async
    func handleTapFixPrompt() async
}

@MainActor
protocol ExpenseAIEntryRoutingLogic: Sendable {
    func close()
    func presentError(with text: String)
    func presentNoExpenseAlert(output: ExpenseAIEntryNoExpenseAlertOutput)
    func dismissNoExpenseAlert()
    func openSubscription(
        currentTier: String,
        output: SubscriptionOutput
    )
    func openManualEntry(initialDrafts: [ExpenseEditableDraft]) async
}

final class ExpenseAIEntryRouter: ExpenseAIEntryRoutingLogic {
    private let screenRouter: ScreenNavigator
    private let screens: AddExpenseScreens
    private let toastPresenter: ToastPresenting
    private let noExpenseAlertPresenter: ExpenseAIEntryNoExpenseAlertPresenting

    weak var viewController: UIViewController?

    init(
        screenRouter: ScreenNavigator,
        screens: AddExpenseScreens,
        toastPresenter: ToastPresenting,
        noExpenseAlertPresenter: ExpenseAIEntryNoExpenseAlertPresenting
    ) {
        self.screenRouter = screenRouter
        self.screens = screens
        self.toastPresenter = toastPresenter
        self.noExpenseAlertPresenter = noExpenseAlertPresenter
    }

    func close() {
        noExpenseAlertPresenter.dismiss()
        let container = viewController?.navigationController ?? viewController

        screenRouter.navigate(from: container) { route in
            route.dimiss()
        }
    }

    func presentError(with text: String) {
        toastPresenter.present(state: .error, title: text)
    }

    func presentNoExpenseAlert(output: ExpenseAIEntryNoExpenseAlertOutput) {
        noExpenseAlertPresenter.present(
            addManuallyCommand: Command { [weak output] in
                await output?.handleTapAddManually()
            },
            fixPromptCommand: Command { [weak output] in
                await output?.handleTapFixPrompt()
            }
        )
    }

    func dismissNoExpenseAlert() {
        noExpenseAlertPresenter.dismiss()
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

    func openManualEntry(initialDrafts: [ExpenseEditableDraft]) async {
        noExpenseAlertPresenter.dismiss()
        let container = viewController?.navigationController ?? viewController

        screenRouter.navigate(from: container) { route in
            route.dimissAndPresent(
                screens.manualEntryScreen(initialDrafts: initialDrafts)
                    .withBottomSheet(.init(detents: [.content])),
                animated: true
            )
        }
    }
}
