// Created by Egor Shkarin 14.03.2026

import UIKit

final class LoginViewController: UIViewController, HasContentView {
    typealias ContentView = LoginView

    private let interactor: LoginBusinessLogic
    private let viewModelStore: ViewModelStore<LoginViewModel>

    init(
        interactor: LoginBusinessLogic,
        viewModelStore: ViewModelStore<LoginViewModel>
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

private extension LoginViewController {
    func render(with viewModel: LoginViewModel) {
        contentView.configure(with: viewModel)
    }
}
