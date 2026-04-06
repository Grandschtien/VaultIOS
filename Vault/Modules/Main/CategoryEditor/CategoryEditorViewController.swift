import UIKit

final class CategoryEditorViewController: UIViewController, HasContentView, AddExpenseSheetContentSizing {
    typealias ContentView = CategoryEditorView

    private let interactor: CategoryEditorBusinessLogic
    private let viewModelStore: ViewModelStore<CategoryEditorViewModel>

    init(
        interactor: CategoryEditorBusinessLogic,
        viewModelStore: ViewModelStore<CategoryEditorViewModel>
    ) {
        self.interactor = interactor
        self.viewModelStore = viewModelStore
        super.init(nibName: nil, bundle: nil)
    }

    override func loadView() {
        view = ContentView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModelStore.onViewModelChange = { [weak self] viewModel in
            self?.render(with: viewModel)
        }

        Task { [weak self] in
            await self?.interactor.fetchData()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if isMovingFromParent || isBeingDismissed {
            navigationController?.setNavigationBarHidden(false, animated: animated)
        }
    }
}

private extension CategoryEditorViewController {
    func render(with viewModel: CategoryEditorViewModel) {
        contentView.configure(with: viewModel)
    }
}
