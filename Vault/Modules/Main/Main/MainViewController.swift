// Created by Egor Shkarin 23.03.2026

import UIKit

final class MainViewController: UIViewController, HasContentView {
    typealias ContentView = MainView

    private let interactor: MainBusinessLogic
    private let viewModelStore: ViewModelStore<MainViewModel>

    init(
        interactor: MainBusinessLogic,
        viewModelStore: ViewModelStore<MainViewModel>
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

private extension MainViewController {
    func render(with viewModel: MainViewModel) {
        contentView.configure(with: viewModel)
        tabBarController?.tabBar.isUserInteractionEnabled = !viewModel.isInteractionBlocked
        navigationController?.navigationBar.isUserInteractionEnabled = !viewModel.isInteractionBlocked
    }
}
