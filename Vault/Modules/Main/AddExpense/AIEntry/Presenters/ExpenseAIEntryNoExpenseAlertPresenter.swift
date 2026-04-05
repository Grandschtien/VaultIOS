import UIKit
import SnapKit

@MainActor
protocol ExpenseAIEntryNoExpenseAlertPresenting: Sendable {
    func present(
        addManuallyCommand: Command,
        fixPromptCommand: Command
    )
    func dismiss()
}

final class ExpenseAIEntryNoExpenseAlertPresenter: ExpenseAIEntryNoExpenseAlertPresenting {
    private enum Constants {
        static let showAnimationDuration: TimeInterval = 0.2
        static let hideAnimationDuration: TimeInterval = 0.16
    }

    private let windowProvider: @MainActor () -> UIWindow?
    @MainActor
    private var currentAlertView: ExpenseAIEntryNoExpenseAlertView?

    init(
        windowProvider: @escaping @MainActor () -> UIWindow? = ExpenseAIEntryNoExpenseAlertPresenter.resolveCurrentWindow
    ) {
        self.windowProvider = windowProvider
    }

    func present(
        addManuallyCommand: Command,
        fixPromptCommand: Command
    ) {
        guard let window = windowProvider() else {
            return
        }

        dismiss()

        let alertView = ExpenseAIEntryNoExpenseAlertView()
        alertView.apply(
            .init(
                title: .init(
                    text: L10n.expenseAiEntryNoExpenseTitle,
                    font: Typography.typographyBold20,
                    textColor: Asset.Colors.textAndIconPrimary.color,
                    alignment: .center
                ),
                message: .init(
                    text: L10n.expenseAiEntryNoExpenseMessage,
                    font: Typography.typographyRegular16,
                    textColor: Asset.Colors.textAndIconSecondary.color,
                    alignment: .center,
                    numberOfLines: 0
                ),
                addManuallyButton: .init(
                    title: L10n.expenseAiEntryAddManually,
                    titleColor: Asset.Colors.textAndIconPrimaryInverted.color,
                    backgroundColor: Asset.Colors.interactiveElemetsPrimary.color,
                    font: Typography.typographySemibold16,
                    tapCommand: wrappedCommand(addManuallyCommand)
                ),
                fixPromptButton: .init(
                    title: L10n.expenseAiEntryFixPrompt,
                    titleColor: Asset.Colors.textAndIconPrimary.color,
                    backgroundColor: Asset.Colors.backgroundPrimary.color,
                    font: Typography.typographySemibold16,
                    tapCommand: wrappedCommand(fixPromptCommand)
                )
            )
        )

        window.addSubview(alertView)
        alertView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        alertView.alpha = 0
        UIView.animate(
            withDuration: Constants.showAnimationDuration,
            delay: 0,
            options: [.curveEaseOut, .allowUserInteraction]
        ) {
            alertView.alpha = 1
        }

        currentAlertView = alertView
    }

    func dismiss() {
        guard let currentAlertView else {
            return
        }

        self.currentAlertView = nil

        UIView.animate(
            withDuration: Constants.hideAnimationDuration,
            delay: 0,
            options: [.curveEaseIn, .allowUserInteraction]
        ) {
            currentAlertView.alpha = 0
        } completion: { _ in
            currentAlertView.removeFromSuperview()
        }
    }
}

private extension ExpenseAIEntryNoExpenseAlertPresenter {
    func wrappedCommand(_ command: Command) -> Command {
        Command { [weak self] in
            self?.dismiss()
            command.execute()
        }
    }

    @MainActor
    static func resolveCurrentWindow() -> UIWindow? {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }

        let activeScenes = scenes.filter {
            $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive
        }

        for scene in activeScenes + scenes {
            if let keyWindow = scene.windows.first(where: \.isKeyWindow) {
                return keyWindow
            }

            if let window = scene.windows.last {
                return window
            }
        }

        return nil
    }
}
