// Created by Egor Shkarin 11.03.2026

import UIKit

final class OnboardingViewController: UIViewController, HasContentView {
    typealias ContentView = OnboardingView

    private let interactor: OnboardingBusinessLogic
    private let viewModelStore: ViewModelStore<OnboardingViewModel>
    private var lastAppliedScrollCommand: OnboardingViewModel.ScrollCommand?

    init(
        interactor: OnboardingBusinessLogic,
        viewModelStore: ViewModelStore<OnboardingViewModel>
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

private extension OnboardingViewController {
    func render(with viewModel: OnboardingViewModel) {
        contentView.configure(with: viewModel)
        applyScrollCommand(viewModel.scrollCommand)
    }

    func applyScrollCommand(_ command: OnboardingViewModel.ScrollCommand?) {
        guard let command else {
            lastAppliedScrollCommand = nil
            return
        }

        guard command != lastAppliedScrollCommand else {
            return
        }

        lastAppliedScrollCommand = command
        contentView.scrollToPage(command.page, animated: command.isAnimated)
    }
}
