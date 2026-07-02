import SwiftUI
import UIKit

final class AnalyticsViewController: UIHostingController<AnalyticsView> {

    private let interactor: AnalyticsBusinessLogic
    private let viewModelStore: ViewModelStore<AnalyticsViewModel>
    private let periodBarButtonView = AnalyticsMonthBarButtonView()

    init(
        interactor: AnalyticsBusinessLogic,
        viewModelStore: ViewModelStore<AnalyticsViewModel>
    ) {
        self.interactor = interactor
        self.viewModelStore = viewModelStore
        super.init(rootView: AnalyticsView(viewModelStore: viewModelStore))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Asset.Colors.backgroundPrimary.color
        render(with: viewModelStore.viewModel)

        viewModelStore.onViewModelChange = { [weak self] viewModel in
            self?.render(with: viewModel)
        }

        Task { [weak self] in
            await self?.interactor.fetchData()
        }
    }
}

private extension AnalyticsViewController {
    func render(with viewModel: AnalyticsViewModel) {
        navigationItem.title = nil
        navigationItem.leftBarButtonItem = nil

        if case .locked = viewModel.state {
            navigationItem.titleView = nil
            return
        }

        let shouldAnimatePeriodButton = navigationItem.titleView === periodBarButtonView
        periodBarButtonView.configure(
            with: viewModel.periodButton,
            animated: shouldAnimatePeriodButton
        )
        navigationItem.titleView = periodBarButtonView
    }
}
