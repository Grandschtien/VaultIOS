import UIKit
import Nivelir
import Foundation

final class CategoryEditorFactory: Screen {
    private let mode: CategoryEditorMode
    private let context: MainFlowContext

    init(
        mode: CategoryEditorMode,
        context: MainFlowContext
    ) {
        self.mode = mode
        self.context = context
    }

    func build(navigator: ScreenNavigator) -> UIViewController {
        @SafeInject
        var toastPresenter: ToastPresenting

        let presetProvider = CategoryEditorPresetProvider()
        let colorProvider = CategoryColorProvider()
        let viewModel = CategoryEditorViewModel()
        let presenter = CategoryEditorPresenter(
            viewModel: viewModel,
            presetProvider: presetProvider,
            colorProvider: colorProvider
        )
        let router = CategoryEditorRouter(
            screenRouter: navigator,
            context: context,
            toastPresenter: toastPresenter,
            colorProvider: colorProvider
        )
        let interactor = CategoryEditorInteractor(
            mode: mode,
            presenter: presenter,
            router: router,
            repository: context.repository,
            observer: context.observer,
            presetProvider: presetProvider,
            colorProvider: colorProvider
        )

        let viewModelStore = ViewModelStore(
            viewModel: presenter.viewModel,
            options: .applyInitial,
            publisher: presenter.$viewModel
        )

        let controller = CategoryEditorViewController(
            interactor: interactor,
            viewModelStore: viewModelStore
        )

        presenter.handler = interactor
        router.viewController = controller
        router.systemPickerOutput = interactor

        return controller
    }
}
