// Created by Egor Shkarin 08.04.2026

import UIKit

final class SubscriptionViewController: UIViewController, HasContentView {
    typealias ContentView = SubscriptionView

    private let interactor: SubscriptionBusinessLogic
    private let viewModelStore: ViewModelStore<SubscriptionViewModel>

    init(
        interactor: SubscriptionBusinessLogic,
        viewModelStore: ViewModelStore<SubscriptionViewModel>
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

private extension SubscriptionViewController {
    func render(with viewModel: SubscriptionViewModel) {
        contentView.configure(with: viewModel)
    }
}
