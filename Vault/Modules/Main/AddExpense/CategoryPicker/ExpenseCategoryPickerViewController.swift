import UIKit

final class ExpenseCategoryPickerViewController: UIViewController, HasContentView, AddExpenseSheetContentSizing {
    typealias ContentView = ExpenseCategoryPickerView

    private let interactor: ExpenseCategoryPickerBusinessLogic
    private let viewModelStore: ViewModelStore<ExpenseCategoryPickerViewModel>
    private let tableAdapter: ExpenseCategoryPickerTableAdapter

    init(
        interactor: ExpenseCategoryPickerBusinessLogic,
        viewModelStore: ViewModelStore<ExpenseCategoryPickerViewModel>,
        tableAdapter: ExpenseCategoryPickerTableAdapter
    ) {
        self.interactor = interactor
        self.viewModelStore = viewModelStore
        self.tableAdapter = tableAdapter
        super.init(nibName: nil, bundle: nil)
    }

    override func loadView() {
        view = ContentView(tableAdapter: tableAdapter)
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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updatePreferredContentSizeToFitContent()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        schedulePreferredContentSizeUpdate()
    }
}

private extension ExpenseCategoryPickerViewController {
    func render(with viewModel: ExpenseCategoryPickerViewModel) {
        contentView.configure(with: viewModel)
        schedulePreferredContentSizeUpdate()
    }
}
