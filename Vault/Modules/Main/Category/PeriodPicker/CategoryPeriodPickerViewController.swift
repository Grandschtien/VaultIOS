import UIKit

final class CategoryPeriodPickerViewController: UIViewController, HasContentView {
    typealias ContentView = CategoryPeriodPickerView

    private let interactor: CategoryPeriodPickerBusinessLogic
    private let viewModelStore: ViewModelStore<CategoryPeriodPickerViewModel>
    private let closeBarButtonView = CategoryPeriodPickerCloseBarButtonView()
    private let confirmBarButtonView = CategoryPeriodPickerConfirmBarButtonView()

    init(
        interactor: CategoryPeriodPickerBusinessLogic,
        viewModelStore: ViewModelStore<CategoryPeriodPickerViewModel>
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
}

private extension CategoryPeriodPickerViewController {
    func render(with viewModel: CategoryPeriodPickerViewModel) {
        title = viewModel.navigationTitle.text
        contentView.configure(with: viewModel)
        closeBarButtonView.configure(with: viewModel.closeButton)
        confirmBarButtonView.configure(with: viewModel.confirmButton)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: closeBarButtonView)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: confirmBarButtonView)
    }
}
