import UIKit
import Nivelir

@MainActor
protocol MainFlowRootRoutingLogic: Sendable {
    func openSubscription(
        from viewController: UIViewController,
        currentTier: SubscriptionTier,
        output: SubscriptionOutput
    )
}

final class MainFlowRootRouter: MainFlowRootRoutingLogic {
    private let screenNavigator: ScreenNavigator

    init(screenNavigator: ScreenNavigator) {
        self.screenNavigator = screenNavigator
    }

    func openSubscription(
        from viewController: UIViewController,
        currentTier: SubscriptionTier,
        output: SubscriptionOutput
    ) {
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
