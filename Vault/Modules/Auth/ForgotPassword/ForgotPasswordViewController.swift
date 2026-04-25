import UIKit

final class ForgotPasswordViewController: UIViewController, HasContentView, AddExpenseSheetContentSizing {
    typealias ContentView = ForgotPasswordView

    private let interactor: ForgotPasswordBusinessLogic
    private let viewModelStore: ViewModelStore<ForgotPasswordViewModel>

    init(
        interactor: ForgotPasswordBusinessLogic,
        viewModelStore: ViewModelStore<ForgotPasswordViewModel>
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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updatePreferredContentSizeToFitContent()
    }
}

private extension ForgotPasswordViewController {
    func render(with viewModel: ForgotPasswordViewModel) {
        contentView.configure(with: viewModel)
        updatePreferredContentSizeToFitContent()
    }
}
