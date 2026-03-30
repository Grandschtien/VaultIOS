// Created by Egor Shkarin 29.03.2026

import UIKit

final class ProfileViewController: UIViewController, HasContentView {
    typealias ContentView = ProfileView

    private let interactor: ProfileBusinessLogic
    private let viewModelStore: ViewModelStore<ProfileViewModel>

    init(
        interactor: ProfileBusinessLogic,
        viewModelStore: ViewModelStore<ProfileViewModel>
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
    }
}

private extension ProfileViewController {
    func render(with viewModel: ProfileViewModel) {
        contentView.configure(with: viewModel)
    }
}
