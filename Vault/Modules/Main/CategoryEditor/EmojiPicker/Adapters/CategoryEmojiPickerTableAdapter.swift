import UIKit

protocol CategoryEmojiPickerTableAdapterOutput: AnyObject {
    func handleDidSelectEmojiRow(at index: Int)
}

final class CategoryEmojiPickerTableAdapter: NSObject, LayoutScaleProviding {
    weak var output: CategoryEmojiPickerTableAdapterOutput?

    private var rows: [CategoryEmojiPickerViewModel.RowViewModel] = []

    func attach(to tableView: UITableView) {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(CategoryEmojiPickerCell.self)
    }

    func configure(rows: [CategoryEmojiPickerViewModel.RowViewModel]) {
        self.rows = rows
    }
}

extension CategoryEmojiPickerTableAdapter: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(CategoryEmojiPickerCell.self, for: indexPath)
        cell.configure(with: rows[indexPath.row])
        return cell
    }
}

extension CategoryEmojiPickerTableAdapter: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        output?.handleDidSelectEmojiRow(at: indexPath.row)
    }
}
