import UIKit

final class ExpenseEntryChooserViewController: UIViewController, HasContentView {
    typealias ContentView = ExpenseEntryChooserView

    private let interactor: ExpenseEntryChooserBusinessLogic
    private let viewModelStore: ViewModelStore<ExpenseEntryChooserViewModel>

    init(
        interactor: ExpenseEntryChooserBusinessLogic,
        viewModelStore: ViewModelStore<ExpenseEntryChooserViewModel>
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

private extension ExpenseEntryChooserViewController {
    func render(with viewModel: ExpenseEntryChooserViewModel) {
        contentView.configure(with: viewModel)
    }
}
