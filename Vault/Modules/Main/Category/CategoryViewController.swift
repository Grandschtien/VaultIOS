// Created by Egor Shkarin on 28.03.2026

import UIKit

final class CategoryViewController: UIViewController, HasContentView {
    typealias ContentView = CategoryView

    private let interactor: CategoryBusinessLogic
    private let viewModelStore: ViewModelStore<CategoryViewModel>
    private let collectionAdapter: CategoryExpensesCollectionViewAdapter

    init(
        interactor: CategoryBusinessLogic,
        viewModelStore: ViewModelStore<CategoryViewModel>,
        collectionAdapter: CategoryExpensesCollectionViewAdapter
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

private extension CategoryViewController {
    func render(with viewModel: CategoryViewModel) {
        title = viewModel.navigationTitle.text
        contentView.configure(with: viewModel)
    }
}
