import UIKit

final class ProfileCurrencyViewController: UIViewController, HasContentView {
    typealias ContentView = ProfileCurrencyView

    private let interactor: ProfileCurrencyBusinessLogic
    private let viewModelStore: ViewModelStore<ProfileCurrencyViewModel>
    private let tableAdapter: ProfileCurrencyTableAdapter
    private let closeBarButtonView = ProfileCurrencyCloseBarButtonView()

    init(
        interactor: ProfileCurrencyBusinessLogic,
        viewModelStore: ViewModelStore<ProfileCurrencyViewModel>,
        tableAdapter: ProfileCurrencyTableAdapter
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
}

private extension ProfileCurrencyViewController {
    func render(with viewModel: ProfileCurrencyViewModel) {
        title = viewModel.navigationTitle.text
        contentView.configure(with: viewModel)
        closeBarButtonView.configure(with: viewModel.closeButton)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: closeBarButtonView)
    }
}
