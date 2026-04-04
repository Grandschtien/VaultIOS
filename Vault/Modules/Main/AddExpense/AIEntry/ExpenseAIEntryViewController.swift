import UIKit

final class ExpenseAIEntryViewController: UIViewController, HasContentView {
    typealias ContentView = ExpenseAIEntryView

    private let interactor: ExpenseAIEntryBusinessLogic
    private let viewModelStore: ViewModelStore<ExpenseAIEntryViewModel>

    init(
        interactor: ExpenseAIEntryBusinessLogic,
        viewModelStore: ViewModelStore<ExpenseAIEntryViewModel>
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
}

private extension ExpenseAIEntryViewController {
    func render(with viewModel: ExpenseAIEntryViewModel) {
        contentView.configure(with: viewModel)
    }
}
