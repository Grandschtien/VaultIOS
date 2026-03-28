// Created by Codex on 27.03.2026

import UIKit

final class CategoriesListViewController: UIViewController, HasContentView {
    typealias ContentView = CategoriesListView

    private let interactor: CategoriesListBusinessLogic
    private let viewModelStore: ViewModelStore<CategoriesListViewModel>
    private let collectionAdapter: CategoryCollectionViewAdapter

    init(
        interactor: CategoriesListBusinessLogic,
        viewModelStore: ViewModelStore<CategoriesListViewModel>,
        collectionAdapter: CategoryCollectionViewAdapter
    ) {
        self.interactor = interactor
        self.viewModelStore = viewModelStore
        self.collectionAdapter = collectionAdapter
        super.init(nibName: nil, bundle: nil)
    }

    override func loadView() {
        view = ContentView(collectionAdapter: collectionAdapter)
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

private extension CategoriesListViewController {
    func render(with viewModel: CategoriesListViewModel) {
        title = viewModel.navigationTitle.text
        contentView.configure(with: viewModel)
    }
}
