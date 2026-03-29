// Created by Codex on 28.03.2026

import UIKit
import SnapKit
import SkeletonView

protocol CategoryExpensesCollectionViewAdapterOutput: AnyObject {
    func handleNeedLoadNextPage()
}

final class CategoryExpensesCollectionViewAdapter: NSObject, LayoutScaleProviding {
    private enum Constants {
        static let summaryCellReuseId = "CategorySummaryTableViewCell"
        static let expenseCellReuseId = "CategoryExpenseTableViewCell"
        static let summarySectionID = "category-summary-section"
        static let summaryItemID = "category-summary-item"
    }

    private enum ItemKind {
        case summary(CategoryViewModel.SummaryViewModel)
        case expense(CategoryViewModel.ExpenseItemViewModel)
    }

    weak var output: CategoryExpensesCollectionViewAdapterOutput?

    private weak var tableView: UITableView?
    private var dataSource: UITableViewDiffableDataSource<String, String>?

    private var sections: [CategoryViewModel.SectionViewModel] = []
    private var sectionIdentifiers: [String] = []
    private var sectionTitles: [String: Label.LabelViewModel] = [:]
    private var itemKinds: [String: ItemKind] = [:]

    private var hasMore: Bool = false
    private var isLoadingNextPage: Bool = false

    func attach(to tableView: UITableView) {
        self.tableView = tableView

        tableView.register(
            CategorySummaryTableViewCell.self,
            forCellReuseIdentifier: Constants.summaryCellReuseId
        )
        tableView.register(
            CategoryExpenseTableViewCell.self,
            forCellReuseIdentifier: Constants.expenseCellReuseId
        )
        tableView.delegate = self

        dataSource = UITableViewDiffableDataSource<String, String>(
            tableView: tableView,
            cellProvider: { [weak self] tableView, indexPath, itemID in
                guard let self,
                      let itemKind = self.itemKinds[itemID] else {
                    return UITableViewCell()
                }

                switch itemKind {
                case let .summary(summaryViewModel):
                    guard let cell = tableView.dequeueReusableCell(
                        withIdentifier: Constants.summaryCellReuseId,
                        for: indexPath
                    ) as? CategorySummaryTableViewCell else {
                        return UITableViewCell()
                    }

                    cell.configure(with: summaryViewModel)
                    return cell

                case let .expense(expenseViewModel):
                    guard let cell = tableView.dequeueReusableCell(
                        withIdentifier: Constants.expenseCellReuseId,
                        for: indexPath
                    ) as? CategoryExpenseTableViewCell else {
                        return UITableViewCell()
                    }

                    cell.configure(with: self.makeExpenseCellViewModel(from: expenseViewModel))
                    return cell
                }
            }
        )
    }

    func configure(
        summary: CategoryViewModel.SummaryViewModel,
        sections: [CategoryViewModel.SectionViewModel],
        hasMore: Bool,
        isLoadingNextPage: Bool
    ) {
        self.sections = sections
        self.hasMore = hasMore
        self.isLoadingNextPage = isLoadingNextPage
        sectionIdentifiers = []
        sectionTitles = [:]
        itemKinds = [:]

        var snapshot = NSDiffableDataSourceSnapshot<String, String>()

        snapshot.appendSections([Constants.summarySectionID])
        snapshot.appendItems([Constants.summaryItemID], toSection: Constants.summarySectionID)
        snapshot.reloadItems([Constants.summaryItemID])
        sectionIdentifiers.append(Constants.summarySectionID)
        itemKinds[Constants.summaryItemID] = .summary(summary)

        for section in sections {
            let sectionID = "category-expenses-section-\(section.id)"
            sectionIdentifiers.append(sectionID)
            sectionTitles[sectionID] = section.title
            snapshot.appendSections([sectionID])

            let itemIDs = section.items.map { item in
                let itemID = makeItemIdentifier(sectionID: sectionID, item: item)
                itemKinds[itemID] = .expense(item)
                return itemID
            }

            snapshot.appendItems(itemIDs, toSection: sectionID)
        }

        dataSource?.apply(snapshot, animatingDifferences: true)
    }
}

private extension CategoryExpensesCollectionViewAdapter {
    func makeItemIdentifier(
        sectionID: String,
        item: CategoryViewModel.ExpenseItemViewModel
    ) -> String {
        if item.isLoading {
            return "\(sectionID)-\(item.id)"
        }

        return item.id
    }

    func makeExpenseCellViewModel(
        from viewModel: CategoryViewModel.ExpenseItemViewModel
    ) -> ExpenseCollectionViewCell.ViewModel {
        .init(
            id: viewModel.id,
            iconText: viewModel.iconText,
            title: viewModel.title,
            subtitle: viewModel.subtitle,
            amount: viewModel.amount,
            iconBackgroundColor: viewModel.iconBackgroundColor,
            tapCommand: .nope,
            isLoading: viewModel.isLoading
        )
    }

    func sectionIdentifier(for section: Int) -> String? {
        guard sectionIdentifiers.indices.contains(section) else {
            return nil
        }

        return sectionIdentifiers[section]
    }

    func shouldRequestNextPage(for indexPath: IndexPath) -> Bool {
        guard hasMore, !isLoadingNextPage else {
            return false
        }

        guard !sections.isEmpty else {
            return false
        }

        let lastExpenseSectionIndex = sections.count - 1
        let lastTableSectionIndex = lastExpenseSectionIndex + 1

        guard sections[lastExpenseSectionIndex].items.indices.contains(indexPath.row) else {
            return false
        }

        let lastItemIndex = sections[lastExpenseSectionIndex].items.count - 1
        return indexPath.section == lastTableSectionIndex && indexPath.row == lastItemIndex
    }

    func shouldDisplayHeader(for sectionID: String) -> Bool {
        guard sectionID != Constants.summarySectionID else {
            return false
        }

        let title = sectionTitles[sectionID]?.text.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return !title.isEmpty
    }
}

extension CategoryExpensesCollectionViewAdapter: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let sectionID = sectionIdentifier(for: section),
              shouldDisplayHeader(for: sectionID) else {
            return nil
        }

        let headerView = CategoryTableSectionHeaderView()
        headerView.configure(with: sectionTitles[sectionID] ?? .init())
        return headerView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let sectionID = sectionIdentifier(for: section),
              shouldDisplayHeader(for: sectionID) else {
            return .leastNonzeroMagnitude
        }

        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        guard let sectionID = sectionIdentifier(for: section),
              shouldDisplayHeader(for: sectionID) else {
            return .leastNonzeroMagnitude
        }

        return sizeM
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UIView()
        footerView.backgroundColor = .clear
        return footerView
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard let sectionID = sectionIdentifier(for: section),
              sectionID == Constants.summarySectionID else {
            return .leastNonzeroMagnitude
        }

        return spaceXXS
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let sectionID = sectionIdentifier(for: indexPath.section),
              sectionID != Constants.summarySectionID else {
            return UITableView.automaticDimension
        }

        return sizeXL
    }

    func tableView(
        _ tableView: UITableView,
        willDisplay cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        guard shouldRequestNextPage(for: indexPath) else {
            return
        }

        output?.handleNeedLoadNextPage()
    }
}

private final class CategoryTableSectionHeaderView: UIView, LayoutScaleProviding {
    private let titleLabel = Label()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with viewModel: Label.LabelViewModel) {
        titleLabel.apply(viewModel)
    }
}

private extension CategoryTableSectionHeaderView {
    func setupViews() {
        backgroundColor = Asset.Colors.backgroundPrimary.color
    }

    func setupLayout() {
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.bottom.equalToSuperview().inset(spaceXXS)
        }
    }
}

private final class CategorySummaryTableViewCell: UITableViewCell {
    private let summaryView = CategorySummaryView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        contentView.addSubview(summaryView)

        summaryView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with viewModel: CategoryViewModel.SummaryViewModel) {
        summaryView.configure(with: viewModel)
    }
}

private final class CategoryExpenseTableViewCell: UITableViewCell, LayoutScaleProviding {
    private(set) var viewModel: ExpenseCollectionViewCell.ViewModel = .init()

    private let cardView = UIView()
    private let iconBackgroundView = UIView()
    private let iconLabel = Label()
    private let titleLabel = Label()
    private let subtitleLabel = Label()
    private let amountLabel = Label()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        hideSkeleton()
    }

    func configure(with viewModel: ExpenseCollectionViewCell.ViewModel) {
        self.viewModel = viewModel

        if viewModel.isLoading {
            showSkeleton()
            return
        }

        hideSkeleton()

        iconLabel.apply(
            .init(
                text: viewModel.iconText,
                font: Typography.typographyBold18,
                textColor: Asset.Colors.textAndIconSecondary.color,
                alignment: .center
            )
        )
        titleLabel.apply(viewModel.title)
        subtitleLabel.apply(viewModel.subtitle)
        amountLabel.apply(viewModel.amount)

        iconBackgroundView.backgroundColor = viewModel.iconBackgroundColor
    }
}

private extension CategoryExpenseTableViewCell {
    func setupViews() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        cardView.isSkeletonable = true
        cardView.backgroundColor = Asset.Colors.interactiveInputBackground.color
        cardView.layer.cornerRadius = sizeL

        iconBackgroundView.layer.cornerRadius = sizeS
    }

    func setupLayout() {
        contentView.addSubview(cardView)
        [iconBackgroundView, titleLabel, subtitleLabel, amountLabel].forEach {
            cardView.addSubview($0)
        }
        iconBackgroundView.addSubview(iconLabel)

        cardView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.bottom.equalToSuperview().inset(spaceXXXS)
        }

        iconBackgroundView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(spaceS)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(sizeL)
        }

        iconLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconBackgroundView.snp.trailing).offset(spaceS)
            make.top.equalToSuperview().offset(spaceS)
            make.trailing.lessThanOrEqualTo(amountLabel.snp.leading).offset(-spaceS)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(spaceXXXS)
            make.trailing.lessThanOrEqualTo(amountLabel.snp.leading).offset(-spaceS)
        }

        amountLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(spaceS)
            make.leading.greaterThanOrEqualTo(subtitleLabel.snp.trailing).offset(spaceXS)
        }
    }

    func showSkeleton() {
        iconLabel.isHidden = true
        titleLabel.isHidden = true
        subtitleLabel.isHidden = true
        amountLabel.isHidden = true

        cardView.skeletonCornerRadius = Float(cardView.layer.cornerRadius)
        cardView.showAnimatedGradientSkeleton()
    }

    func hideSkeleton() {
        iconLabel.isHidden = false
        titleLabel.isHidden = false
        subtitleLabel.isHidden = false
        amountLabel.isHidden = false

        cardView.hideSkeleton()
    }
}
