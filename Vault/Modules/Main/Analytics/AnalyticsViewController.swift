import UIKit

final class AnalyticsViewController: UIViewController, HasContentView {
    typealias ContentView = AnalyticsView

    private let interactor: AnalyticsBusinessLogic
    private let viewModelStore: ViewModelStore<AnalyticsViewModel>
    private let tableAdapter: AnalyticsCategorySummaryTableAdapter

    init(
        interactor: AnalyticsBusinessLogic,
        viewModelStore: ViewModelStore<AnalyticsViewModel>,
        tableAdapter: AnalyticsCategorySummaryTableAdapter
    ) {
        self.interactor = interactor
        self.viewModelStore = viewModelStore
        self.tableAdapter = tableAdapter
        super.init(nibName: nil, bundle: nil)
    }

    override func loadView() {
        view = ContentView(tableAdapter: tableAdapter)
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

private extension AnalyticsViewController {
    func render(with viewModel: AnalyticsViewModel) {
        contentView.configure(with: viewModel)
    }
}
