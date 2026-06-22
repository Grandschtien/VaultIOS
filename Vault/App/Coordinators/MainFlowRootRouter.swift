import UIKit
import Nivelir

@MainActor
protocol MainFlowRootRoutingLogic: Sendable {
    func routeToHome()
    func openWidgetEntry(
        context: MainFlowContext,
        destination: VaultWidgetEntryDestination
    )
    func openSubscription(
        currentTier: SubscriptionTier,
        output: SubscriptionOutput
    )
}

final class MainFlowRootRouter: MainFlowRootRoutingLogic {
    private let screenNavigator: ScreenNavigator
    weak var viewController: UIViewController?

    init(screenNavigator: ScreenNavigator) {
        self.screenNavigator = screenNavigator
    }

    func routeToHome() {
        guard let tabBarController = viewController as? UITabBarController else {
            return
        }

        let resetHomeRoot = {
            tabBarController.selectedIndex = .zero
            (tabBarController.selectedViewController as? UINavigationController)?
                .popToRootViewController(animated: false)
        }

        guard tabBarController.presentedViewController != nil else {
            resetHomeRoot()
            return
        }

        tabBarController.dismiss(animated: true) {
            resetHomeRoot()
        }
    }

    func openWidgetEntry(
        context: MainFlowContext,
        destination: VaultWidgetEntryDestination
    ) {
        guard let viewController else {
            return
        }

        let presentEntry = { [screenNavigator] in
            screenNavigator.navigate(from: viewController) { route in
                switch destination {
                case .aiEntry:
                    route.present(
                        ExpenseAIEntryFactory(context: context)
                            .withBottomSheet(
                                .init(
                                    detents: [.content],
                                    prefferedGrabberForMaximumDetentValue: .default
                                )
                            )
                    )
                case .manualEntry:
                    route.present(
                        ExpenseManualEntryFactory(context: context)
                            .withBottomSheet(
                                .init(
                                    detents: [.content],
                                    prefferedGrabberForMaximumDetentValue: .default
                                )
                            )
                    )
                }
            }
        }

        guard viewController.presentedViewController != nil else {
            presentEntry()
            return
        }

        viewController.dismiss(animated: true) {
            presentEntry()
        }
    }

    func openSubscription(
        currentTier: SubscriptionTier,
        output: SubscriptionOutput
    ) {
        guard let viewController else {
            return
        }

        let presentSubscription = { [screenNavigator] in
            screenNavigator.navigate(from: viewController) { route in
                route.present(
                    SubscriptionFactory(
                        currentTier: currentTier,
                        output: output
                    )
                    .withModalPresentationStyle(.pageSheet)
                )
            }
        }

        guard viewController.presentedViewController != nil else {
            presentSubscription()
            return
        }

        viewController.dismiss(animated: true) {
            presentSubscription()
        }
    }
}
