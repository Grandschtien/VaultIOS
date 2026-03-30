// Created by Codex on 28.03.2026

import UIKit
import SnapKit

protocol CategoryExpensesCollectionViewAdapterOutput: AnyObject {
    func handleNeedLoadNextPage()
}

final class CategoryExpensesCollectionViewAdapter: NSObject, LayoutScaleProviding {
    private enum Constants {
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

        tableView.register(CategorySummaryTableViewCell.self)
        tableView.register(BaseTableViewCellWrapper<ExpenseView>.self)
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
                    let cell = tableView.dequeueReusableCell(CategorySummaryTableViewCell.self, for: indexPath)
                    cell.configure(with: summaryViewModel)
                    return cell

                case let .expense(expenseViewModel):
                    let cell = tableView.dequeueReusableCell(BaseTableViewCellWrapper<ExpenseView>.self, for: indexPath)
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
    ) -> ExpenseView.ViewModel {
        .init(
            id: viewModel.id,
            iconText: viewModel.iconText,
            title: viewModel.title,
            subtitle: viewModel.subtitle,
            amount: viewModel.amount,
            iconBackgroundColor: viewModel.iconBackgroundColor,
            tapCommand: .nope
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
