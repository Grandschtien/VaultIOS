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
            subtitle: context.subtitle == nil ? nil : .init(
                text: context.subtitle!,
                font: Typography.typographyRegular14,
                textColor: Asset.Colors.textAndIconPlaceseholder.color,
                alignment: .center,
                numberOfLines: .zero
            ),
            confirmButton: .init(
                title: context.confirmButtonTitle,
                titleColor: buttonTitleColor(for: context.confirmButtonStyle),
                backgroundColor: buttonBackgroundColor(for: context.confirmButtonStyle),
                font: Typography.typographyBold16,
                tapCommand: context.confirmCommand
            ),
            cancelButton: .init(
                title: context.cancelButtonTitle,
                titleColor: buttonTitleColor(for: context.cancelButtonStyle),
                backgroundColor: buttonBackgroundColor(for: context.cancelButtonStyle),
                font: Typography.typographyBold16,
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

    func buttonTitleColor(for style: CommonConfirmationButtonStyle) -> UIColor {
        switch style {
        case .primary:
            Asset.Colors.textAndIconPrimaryInverted.color
        case .secondary:
            Asset.Colors.textAndIconPrimary.color
        case .destructive:
            Asset.Colors.errorColor.color
        }
    }

    func buttonBackgroundColor(for style: CommonConfirmationButtonStyle) -> UIColor {
        switch style {
        case .primary:
            Asset.Colors.interactiveElemetsPrimary.color
        case .secondary, .destructive:
            Asset.Colors.interactiveInputBackground.color
        }
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
