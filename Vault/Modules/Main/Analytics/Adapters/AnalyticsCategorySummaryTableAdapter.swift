import UIKit

final class AnalyticsCategorySummaryTableAdapter: NSObject, LayoutScaleProviding {
    private enum Constants {
        static let sectionID = "analytics-category-summary-section"
    }

    private weak var tableView: UITableView?
    private var dataSource: UITableViewDiffableDataSource<String, String>?
    private var rowsByID: [String: AnalyticsCategorySummaryCell.ViewModel] = [:]
    private var rowIdentifiers: [String] = []

    func attach(to tableView: UITableView) {
        self.tableView = tableView

        tableView.register(AnalyticsCategorySummaryCell.self)
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.showsVerticalScrollIndicator = false
        tableView.isScrollEnabled = false
        tableView.delegate = self

        dataSource = UITableViewDiffableDataSource<String, String>(
            tableView: tableView,
            cellProvider: { [weak self] tableView, indexPath, itemID in
                guard let self,
                      let row = self.rowsByID[itemID] else {
                    return UITableViewCell()
                }

                let cell = tableView.dequeueReusableCell(AnalyticsCategorySummaryCell.self, for: indexPath)
                cell.configure(with: row)
                return cell
            }
        )
    }

    func configure(
        rows: [AnalyticsCategorySummaryCell.ViewModel]
    ) {
        rowsByID = Dictionary(uniqueKeysWithValues: rows.map { ($0.id, $0) })
        rowIdentifiers = rows.map(\.id)

        var snapshot = NSDiffableDataSourceSnapshot<String, String>()
        snapshot.appendSections([Constants.sectionID])
        snapshot.appendItems(rowIdentifiers, toSection: Constants.sectionID)
        snapshot.reloadItems(rowIdentifiers)
        dataSource?.apply(snapshot, animatingDifferences: false)
    }
}

extension AnalyticsCategorySummaryTableAdapter: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard rowIdentifiers.indices.contains(indexPath.row) else {
            return
        }

        rowsByID[rowIdentifiers[indexPath.row]]?.tapCommand.execute()
    }

    func tableView(
        _ tableView: UITableView,
        heightForRowAt indexPath: IndexPath
    ) -> CGFloat {
        UITableView.automaticDimension
    }

    func tableView(
        _ tableView: UITableView,
        estimatedHeightForRowAt indexPath: IndexPath
    ) -> CGFloat {
        sizeXL
    }
}
