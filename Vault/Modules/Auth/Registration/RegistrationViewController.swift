// Created by Egor Shkarin 16.03.2026

import UIKit

final class RegistrationViewController: UIViewController, HasContentView {
    typealias ContentView = RegistrationView

    private let interactor: RegistrationBusinessLogic
    private let viewModelStore: ViewModelStore<RegistrationViewModel>

    init(
        interactor: RegistrationBusinessLogic,
        viewModelStore: ViewModelStore<RegistrationViewModel>
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

        navigationController?.setNavigationBarHidden(false, animated: animated)
        navigationItem.title = ""
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

private extension RegistrationViewController {
    func render(with viewModel: RegistrationViewModel) {
        contentView.configure(with: viewModel)
    }
}
