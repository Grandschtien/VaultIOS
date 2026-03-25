// Created by Egor Shkarin 25.03.2026

import UIKit

final class ExpesiesListViewController: UIViewController, HasContentView {
    typealias ContentView = ExpesiesListView

    private let interactor: ExpesiesListBusinessLogic
    private let viewModelStore: ViewModelStore<ExpesiesListViewModel>

    init(
        interactor: ExpesiesListBusinessLogic,
        viewModelStore: ViewModelStore<ExpesiesListViewModel>
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

private extension ExpesiesListViewController {
    func render(with viewModel: ExpesiesListViewModel) {
        title = viewModel.navigationTitle.text
        contentView.configure(with: viewModel)
    }
}
