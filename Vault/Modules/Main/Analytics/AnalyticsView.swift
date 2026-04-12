import UIKit
import SnapKit

final class AnalyticsView: UIView, LayoutScaleProviding {
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()
    private let periodTitleLabel = Label()
    private let totalAmountLabel = Label()
    private let chartSectionView = AnalyticsChartSectionView()
    private let topCategoriesTitleLabel = Label()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let loadingView = AnalyticsLoadingView()
    private let errorView = FullScreenCommonErrorView()
    private let emptyLabel = Label()
    private let lockedOverlayView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
    private let lockedButton = Button()
    private let tableAdapter: AnalyticsCategorySummaryTableAdapter
    private let monthPill = AnalyticsMonthBarButtonView()
    private var tableHeightConstraint: Constraint?

    init(
        frame: CGRect = .zero,
        tableAdapter: AnalyticsCategorySummaryTableAdapter
    ) {
        self.tableAdapter = tableAdapter
        super.init(frame: frame)
        setupViews()
        setupLayout()
        tableAdapter.attach(to: tableView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if tableHeightConstraint?.layoutConstraints.first?.constant != tableView.contentSize.height {
            self.tableHeightConstraint?.update(offset: self.tableView.contentSize.height)
        }
    }

    func configure(with viewModel: AnalyticsViewModel) {
        switch viewModel.state {
        case .loading:
            showLoadingState()
        case let .error(errorViewModel):
            monthPill.configure(with: viewModel.monthBarButton)
            showErrorState(errorViewModel)
        case let .empty(emptyViewModel):
            monthPill.configure(with: viewModel.monthBarButton)
            showEmptyState(emptyViewModel)
        case let .locked(lockedViewModel):
            showLockedState(lockedViewModel)
        case let .loaded(contentViewModel):
            monthPill.configure(with: viewModel.monthBarButton)
            showLoadedState(contentViewModel)
        }
    }
}

private extension AnalyticsView {
    func setupViews() {
        backgroundColor = Asset.Colors.backgroundPrimary.color

        scrollView.showsVerticalScrollIndicator = false

        stackView.axis = .vertical
        stackView.spacing = spaceM

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        emptyLabel.isHidden = true
        loadingView.isHidden = true
        errorView.isHidden = true
        lockedOverlayView.isHidden = true
    }

    func setupLayout() {
        addSubview(scrollView)
        addSubview(loadingView)
        addSubview(errorView)
        addSubview(emptyLabel)
        addSubview(lockedOverlayView)

        scrollView.addSubview(contentView)
        contentView.addSubview(stackView)
        contentView.addSubview(monthPill)
        lockedOverlayView.contentView.addSubview(lockedButton)
    
        [
            periodTitleLabel,
            totalAmountLabel,
            chartSectionView,
            topCategoriesTitleLabel,
            tableView
        ].forEach { stackView.addArrangedSubview($0) }
        
        monthPill.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(spaceS)
            make.centerX.equalToSuperview()
        }

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        loadingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        errorView.snp.makeConstraints { make in
            make.edges.equalTo(safeAreaLayoutGuide).inset(spaceS)
        }

        emptyLabel.snp.makeConstraints { make in
            make.center.equalTo(safeAreaLayoutGuide)
            make.horizontalEdges.equalTo(safeAreaLayoutGuide).inset(spaceL)
        }

        lockedOverlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        lockedButton.snp.makeConstraints { make in
            make.center.equalTo(safeAreaLayoutGuide)
            make.leading.greaterThanOrEqualTo(safeAreaLayoutGuide).offset(spaceL)
            make.trailing.lessThanOrEqualTo(safeAreaLayoutGuide).inset(spaceL)
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView.snp.width)
        }

        stackView.snp.makeConstraints { make in
            make.top.equalTo(monthPill.snp.bottom).offset(spaceS)
            make.horizontalEdges.equalToSuperview().inset(spaceS)
            make.bottom.equalToSuperview().inset(spaceS)
        }

        chartSectionView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.centerX.equalToSuperview()
        }

        tableView.snp.makeConstraints { make in
            tableHeightConstraint = make.height.equalTo(0).constraint
        }
    }

    func showLoadingState() {
        scrollView.isHidden = true
        errorView.isHidden = true
        emptyLabel.isHidden = true
        lockedOverlayView.isHidden = true
        loadingView.isHidden = false
        loadingView.startAnimating()
    }

    func showErrorState(_ viewModel: FullScreenCommonErrorView.ViewModel) {
        scrollView.isHidden = true
        emptyLabel.isHidden = true
        lockedOverlayView.isHidden = true
        loadingView.stopAnimating()
        loadingView.isHidden = true
        errorView.isHidden = false
        errorView.apply(viewModel)
    }

    func showEmptyState(_ viewModel: Label.LabelViewModel) {
        scrollView.isHidden = true
        errorView.isHidden = true
        lockedOverlayView.isHidden = true
        loadingView.stopAnimating()
        loadingView.isHidden = true
        emptyLabel.isHidden = false
        emptyLabel.apply(viewModel)
    }

    func showLockedState(_ viewModel: AnalyticsViewModel.LockedViewModel) {
        scrollView.isHidden = true
        errorView.isHidden = true
        emptyLabel.isHidden = true
        loadingView.stopAnimating()
        loadingView.isHidden = true
        lockedOverlayView.isHidden = false
        lockedButton.apply(viewModel.button)
    }

    func showLoadedState(_ viewModel: AnalyticsViewModel.ContentViewModel) {
        errorView.isHidden = true
        emptyLabel.isHidden = true
        lockedOverlayView.isHidden = true
        loadingView.stopAnimating()
        loadingView.isHidden = true
        scrollView.isHidden = false

        periodTitleLabel.apply(viewModel.periodTitle)
        totalAmountLabel.apply(viewModel.totalAmount)
        chartSectionView.configure(with: viewModel.chart)
        topCategoriesTitleLabel.apply(viewModel.topCategoriesTitle)
        tableAdapter.configure(rows: viewModel.rows)
    }
}
