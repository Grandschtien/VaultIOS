import UIKit

protocol ExpenseCategoryPickerTableAdapterOutput: AnyObject {
    func handleDidSelectCategoryRow(at index: Int)
}

final class ExpenseCategoryPickerTableAdapter: NSObject {
    weak var output: ExpenseCategoryPickerTableAdapterOutput?

    private var rows: [ExpenseCategoryPickerViewModel.RowViewModel] = []
    private var dataSource: UITableViewDiffableDataSource<Int, Int>?

    func attach(to tableView: UITableView) {
        tableView.register(ExpenseCategoryPickerCell.self)
        tableView.dataSource = nil
        tableView.delegate = self

        dataSource = UITableViewDiffableDataSource<Int, Int>(
            tableView: tableView
        ) { [weak self] tableView, indexPath, itemIdentifier in
            guard let self,
                  self.rows.indices.contains(itemIdentifier) else {
                return UITableViewCell()
            }

            let cell = tableView.dequeueReusableCell(ExpenseCategoryPickerCell.self, for: indexPath)
            cell.configure(with: self.rows[itemIdentifier])
            return cell
        }
    }

    func configure(rows: [ExpenseCategoryPickerViewModel.RowViewModel]) {
        self.rows = rows

        var snapshot = NSDiffableDataSourceSnapshot<Int, Int>()
        snapshot.appendSections([0])
        snapshot.appendItems(Array(rows.indices), toSection: 0)
        dataSource?.apply(snapshot, animatingDifferences: false)
    }
}

extension ExpenseCategoryPickerTableAdapter: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        output?.handleDidSelectCategoryRow(at: indexPath.row)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
