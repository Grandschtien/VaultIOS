import UIKit
import Nivelir

enum AddExpenseBottomSheetBehavior {
    case content
}

protocol AddExpenseSheetContentHeightProviding {
    func preferredContentHeight(for width: CGFloat) -> CGFloat
}

protocol AddExpenseSheetContentSizing: HasContentView where Self: UIViewController {}

private struct AddExpenseBottomSheetMetrics: LayoutScaleProviding {}

private extension AddExpenseBottomSheetBehavior {
    func apply(to viewController: UIViewController) {
        let metrics = AddExpenseBottomSheetMetrics()

        viewController.modalPresentationStyle = .pageSheet

        guard let sheet = viewController.sheetPresentationController else {
            return
        }

        switch self {
        case .content:
            sheet.detents = [.content(for: viewController)]
        }

        sheet.prefersGrabberVisible = true
        sheet.preferredCornerRadius = metrics.sizeS
    }
}

private extension UISheetPresentationController.Detent {
    static func content(
        for viewController: UIViewController
    ) -> UISheetPresentationController.Detent {
        .custom { context in
            min(
                viewController.preferredContentSize.height,
                context.maximumDetentValue
            )
        }
    }
}

private struct ScreenAddExpenseBottomSheetAction<Container: UIViewController>: ScreenAction {
    typealias Output = Void
    typealias State = Never

    let behavior: AddExpenseBottomSheetBehavior

    func perform(
        container: Container,
        navigator: ScreenNavigator,
        completion: @escaping Completion
    ) {
        behavior.apply(to: container)
        completion(.success(()))
    }
}

private struct ScreenPresentWithExpenseBottomSheetAction<
    New: Screen,
    Container: UIViewController
>: ScreenAction where New.Container: UIViewController {
    typealias Output = New.Container
    typealias State = Never

    let screen: New
    let animated: Bool
    let behavior: AddExpenseBottomSheetBehavior

    private struct ContainerAlreadyPresentingError: Error {}

    func perform(
        container: Container,
        navigator: ScreenNavigator,
        completion: @escaping Completion
    ) {
        navigator.logInfo("Presenting \(screen) on \(type(of: container)) with bottom sheet")

        let presented = screen.build(navigator: navigator)
        behavior.apply(to: presented)

        var completed = false

        let completion = { result in
            guard !completed else {
                return
            }

            completed = true
            completion(result)
        }

        container.present(presented, animated: animated) {
            if container.presented === presented {
                completion(.success(presented))
            } else {
                completion(.failure(ContainerAlreadyPresentingError()))
            }
        }

        if container.presented !== presented {
            completion(.failure(ContainerAlreadyPresentingError()))
        }
    }
}

extension ScreenPresentAction {
    public func combine<Action: ScreenAction>(
        with other: Action
    ) -> AnyScreenAction<Container, Void>? {
        guard let other = other.cast(to: ScreenAddExpenseBottomSheetAction<Container>.self) else {
            return nil
        }

        return ScreenPresentWithExpenseBottomSheetAction(
            screen: screen,
            animated: animated,
            behavior: other.behavior
        )
        .eraseToAnyVoidAction()
    }
}

extension ScreenThenable where Current: UIViewController {
    func addingBottomSheet(_ behavior: AddExpenseBottomSheetBehavior) -> Self {
        then(ScreenAddExpenseBottomSheetAction<Current>(behavior: behavior))
    }
}

extension AddExpenseSheetContentSizing where Self: UIViewController, ContentView: UIView {
    func updatePreferredContentSizeToFitContent() {
        let preferredWidth = view.bounds.width > .zero
            ? view.bounds.width
            : view.window?.bounds.width ?? UIScreen.main.bounds.width

        guard preferredWidth > .zero else {
            return
        }

        let preferredHeight: CGFloat
        if let contentView = contentView as? AddExpenseSheetContentHeightProviding {
            preferredHeight = contentView.preferredContentHeight(for: preferredWidth)
        } else {
            preferredHeight = contentView.systemLayoutSizeFitting(
                CGSize(
                    width: preferredWidth,
                    height: UIView.layoutFittingCompressedSize.height
                ),
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel
            ).height
        }

        guard preferredHeight > .zero else {
            return
        }

        let preferredContentSize = CGSize(
            width: preferredWidth,
            height: preferredHeight
        )

        if self.preferredContentSize != preferredContentSize {
            self.preferredContentSize = preferredContentSize
        }

        if navigationController?.preferredContentSize != preferredContentSize {
            navigationController?.preferredContentSize = preferredContentSize
        }

        sheetPresentationController?.invalidateDetents()
        navigationController?.sheetPresentationController?.invalidateDetents()
    }
}
