// Created by Egor Shkarin ___DATE___

import UIKit

final class ___VARIABLE_moduleName___ViewController: UIViewController, HasContentView {
    typealias ContentView = ___VARIABLE_moduleName___View

    private let interactor: ___VARIABLE_moduleName___BusinessLogic
    private let viewModelStore: ViewModelStore<___VARIABLE_moduleName___ViewModel>

    init(
        interactor: ___VARIABLE_moduleName___BusinessLogic,
        viewModelStore: ViewModelStore<___VARIABLE_moduleName___ViewModel>
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

private extension ___VARIABLE_moduleName___ViewController {
    func render(with viewModel: ___VARIABLE_moduleName___ViewModel) {
        contentView.configure(with: viewModel)
    }
}
