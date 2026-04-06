import UIKit
import Nivelir

struct CategoryEmojiPickerFactory: Screen {
    private let selectedEmoji: String
    private let output: CategoryEmojiPickerOutput

    init(
        selectedEmoji: String,
        output: CategoryEmojiPickerOutput
    ) {
        self.selectedEmoji = selectedEmoji
        self.output = output
    }

    func build(navigator: ScreenNavigator) -> UIViewController {
        let presetProvider = CategoryEditorPresetProvider()
        let viewModel = CategoryEmojiPickerViewModel()
        let presenter = CategoryEmojiPickerPresenter(viewModel: viewModel)
        let router = CategoryEmojiPickerRouter(screenRouter: navigator)
        let interactor = CategoryEmojiPickerInteractor(
            selectedEmoji: selectedEmoji,
            presenter: presenter,
            router: router,
            output: output,
            presetProvider: presetProvider
        )

        let viewModelStore = ViewModelStore(
            viewModel: presenter.viewModel,
            options: .applyInitial,
            publisher: presenter.$viewModel
        )

        let tableAdapter = CategoryEmojiPickerTableAdapter()
        let controller = CategoryEmojiPickerViewController(
            interactor: interactor,
            viewModelStore: viewModelStore,
            tableAdapter: tableAdapter
        )

        presenter.handler = interactor
        router.viewController = controller

        return controller
    }
}
