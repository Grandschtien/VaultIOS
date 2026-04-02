// Created by Egor Shkarin 29.03.2026

import UIKit

final class ProfileViewController: UIViewController, HasContentView {
    typealias ContentView = ProfileView

    private let interactor: ProfileBusinessLogic
    private let viewModelStore: ViewModelStore<ProfileViewModel>
    private let saveBarButtonView = ProfileSaveBarButtonView()

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

        Task { [weak self] in
            await self?.interactor.fetchData()
        }
    }
}

private extension ProfileViewController {
    func render(with viewModel: ProfileViewModel) {
        title = viewModel.navigationTitle.text
        contentView.configure(with: viewModel)

        navigationItem.setHidesBackButton(viewModel.isBackButtonHidden, animated: true)

        if let saveButtonViewModel = viewModel.saveCurrencyButton {
            saveBarButtonView.configure(with: saveButtonViewModel)
            navigationItem.leftBarButtonItem = UIBarButtonItem(customView: saveBarButtonView)
        } else {
            navigationItem.leftBarButtonItem = nil
        }
    }
}
