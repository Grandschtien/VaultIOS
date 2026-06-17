import UIKit

final class EmailVerificationViewController: UIViewController, HasContentView {
    typealias ContentView = EmailVerificationView

    private let interactor: EmailVerificationBusinessLogic
    private let viewModelStore: ViewModelStore<EmailVerificationViewModel>

    init(
        interactor: EmailVerificationBusinessLogic,
        viewModelStore: ViewModelStore<EmailVerificationViewModel>
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

        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationItem.title = nil
        navigationItem.largeTitleDisplayMode = .never
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        guard isMovingFromParent || isBeingDismissed else {
            return
        }

        Task { [weak self] in
            await self?.interactor.handleFlowDidExit()
        }
    }
}

private extension EmailVerificationViewController {
    func render(with viewModel: EmailVerificationViewModel) {
        contentView.configure(with: viewModel)
    }
}
