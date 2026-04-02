import UIKit

final class ProfileCurrencyTableAdapter: NSObject, LayoutScaleProviding {
    private enum Constants {
        static let sectionID = "profile-currency-main-section"
    }

    private weak var tableView: UITableView?
    private var dataSource: UITableViewDiffableDataSource<String, String>?
    private var rowsByCode: [String: ProfileCurrencyViewModel.RowViewModel] = [:]
    private var rowIdentifiers: [String] = []

    func attach(to tableView: UITableView) {
        self.tableView = tableView

        tableView.register(ProfileCurrencyCell.self)
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.showsVerticalScrollIndicator = false
        tableView.delegate = self

        dataSource = UITableViewDiffableDataSource<String, String>(
            tableView: tableView,
            cellProvider: { [weak self] tableView, indexPath, itemID in
                guard let self,
                      let row = self.rowsByCode[itemID] else {
                    return UITableViewCell()
                }

                let cell = tableView.dequeueReusableCell(ProfileCurrencyCell.self, for: indexPath)
                cell.configure(with: row)
                return cell
            }
        )
    }

    func configure(rows: [ProfileCurrencyViewModel.RowViewModel]) {
        rowsByCode = Dictionary(uniqueKeysWithValues: rows.map { ($0.code, $0) })
        rowIdentifiers = rows.map(\.code)

        var snapshot = NSDiffableDataSourceSnapshot<String, String>()
        snapshot.appendSections([Constants.sectionID])
        snapshot.appendItems(rowIdentifiers, toSection: Constants.sectionID)
        dataSource?.apply(snapshot, animatingDifferences: true)
    }
}

extension ProfileCurrencyTableAdapter: UITableViewDelegate {
    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard rowIdentifiers.indices.contains(indexPath.row) else {
            return
        }

        let rowID = rowIdentifiers[indexPath.row]
        rowsByCode[rowID]?.tapCommand.execute()
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
