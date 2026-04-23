import UIKit
import Nivelir

struct CommonConfirmationFactory: Screen {
    private let context: CommonConfirmationContext

    init(context: CommonConfirmationContext) {
        self.context = context
    }

    func build(navigator: ScreenNavigator) -> UIViewController {
        let router = CommonConfirmationRouter(screenRouter: navigator)
        let controller = CommonConfirmationViewController(
            viewModel: makeViewModel(router: router)
        )

        router.viewController = controller

        return controller
    }
}

private extension CommonConfirmationFactory {
    func makeViewModel(
        router: CommonConfirmationRoutingLogic
    ) -> CommonConfirmationView.ViewModel {
        CommonConfirmationView.ViewModel(
            title: .init(
                text: context.title,
                font: Typography.typographyBold20,
                textColor: Asset.Colors.textAndIconPrimary.color,
                alignment: .center,
                numberOfLines: .zero
            ),
            confirmButton: .init(
                title: context.confirmButtonTitle,
                titleColor: Asset.Colors.textAndIconPrimaryInverted.color,
                backgroundColor: Asset.Colors.interactiveElemetsPrimary.color,
                font: Typography.typographySemibold16,
                tapCommand: context.confirmCommand
            ),
            cancelButton: .init(
                title: context.cancelButtonTitle,
                titleColor: Asset.Colors.textAndIconPrimary.color,
                backgroundColor: Asset.Colors.interactiveInputBackground.color,
                font: Typography.typographySemibold16,
                tapCommand: resolvedCommand(
                    for: context.cancelAction,
                    router: router
                )
            ),
            closeCommand: resolvedCommand(
                for: context.closeAction,
                router: router
            )
        )
    }

    func resolvedCommand(
        for action: CommonConfirmationCloseAction,
        router: CommonConfirmationRoutingLogic
    ) -> Command {
        switch action {
        case .close:
            return Command {
                await router.close()
            }
        case .custom(let command):
            return command
        }
    }
}
