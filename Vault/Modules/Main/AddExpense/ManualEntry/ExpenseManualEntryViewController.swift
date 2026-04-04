import UIKit

final class ExpenseManualEntryViewController: UIViewController, HasContentView, AddExpenseSheetSizingController {
    typealias ContentView = ExpenseManualEntryView

    private let interactor: ExpenseManualEntryBusinessLogic
    private let viewModelStore: ViewModelStore<ExpenseManualEntryViewModel>

    init(
        interactor: ExpenseManualEntryBusinessLogic,
        viewModelStore: ViewModelStore<ExpenseManualEntryViewModel>
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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updatePreferredContentSizeIfNeeded()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
}

private extension ExpenseManualEntryViewController {
    func render(with viewModel: ExpenseManualEntryViewModel) {
        contentView.configure(with: viewModel)
        updatePreferredContentSizeIfNeeded()
    }
}
