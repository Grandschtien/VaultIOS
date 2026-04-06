import UIKit

final class CategoryEmojiPickerViewController: UIViewController, HasContentView, AddExpenseSheetContentSizing {
    typealias ContentView = CategoryEmojiPickerView

    private let interactor: CategoryEmojiPickerBusinessLogic
    private let viewModelStore: ViewModelStore<CategoryEmojiPickerViewModel>
    private let tableAdapter: CategoryEmojiPickerTableAdapter

    init(
        interactor: CategoryEmojiPickerBusinessLogic,
        viewModelStore: ViewModelStore<CategoryEmojiPickerViewModel>,
        tableAdapter: CategoryEmojiPickerTableAdapter
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
}

private extension CategoryEmojiPickerViewController {
    func render(with viewModel: CategoryEmojiPickerViewModel) {
        contentView.configure(with: viewModel)
    }
}
