import UIKit
import SnapKit

final class CategoryEmojiPickerView: UIView, LayoutScaleProviding {
    private var viewModel: CategoryEmojiPickerViewModel = .init()
    private let tableAdapter: CategoryEmojiPickerTableAdapter

    private let headerView = AddExpenseSheetHeaderView()
    private let searchField = TextField()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyLabel = Label()

    init(
        frame: CGRect = .zero,
        tableAdapter: CategoryEmojiPickerTableAdapter
    ) {
        self.tableAdapter = tableAdapter
        super.init(frame: frame)
        setupViews()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with viewModel: CategoryEmojiPickerViewModel) {
        self.viewModel = viewModel

        headerView.apply(viewModel.header)
        searchField.apply(viewModel.searchField)

        switch viewModel.state {
        case let .empty(label):
            emptyLabel.isHidden = false
            tableView.isHidden = true
            emptyLabel.apply(label)
            tableAdapter.configure(rows: [])
        case let .loaded(rows):
            emptyLabel.isHidden = true
            tableView.isHidden = false
            tableAdapter.configure(rows: rows)
            tableView.reloadData()
        }
    }
}

private extension CategoryEmojiPickerView {
    func setupViews() {
        backgroundColor = Asset.Colors.backgroundPrimary.color

        tableAdapter.output = self
        tableAdapter.attach(to: tableView)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = sizeL

        emptyLabel.isHidden = true
    }

    func setupLayout() {
        addSubview(headerView)
        addSubview(searchField)
        addSubview(tableView)
        addSubview(emptyLabel)

        headerView.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide)
            make.horizontalEdges.equalToSuperview()
        }

        searchField.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(spaceS)
            make.horizontalEdges.equalTo(safeAreaLayoutGuide).inset(spaceS)
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(searchField.snp.bottom).offset(spaceS)
            make.horizontalEdges.equalTo(safeAreaLayoutGuide).inset(spaceS)
            make.bottom.equalTo(safeAreaLayoutGuide).inset(spaceS)
        }

        emptyLabel.snp.makeConstraints { make in
            make.center.equalTo(tableView)
            make.horizontalEdges.equalTo(tableView).inset(spaceS)
        }
    }

    func rows(from state: CategoryEmojiPickerViewModel.State) -> [CategoryEmojiPickerViewModel.RowViewModel] {
        switch state {
        case .empty:
            []
        case let .loaded(rows):
            rows
        }
    }
}

extension CategoryEmojiPickerView: CategoryEmojiPickerTableAdapterOutput {
    func handleDidSelectEmojiRow(at index: Int) {
        let rows = rows(from: viewModel.state)
        guard rows.indices.contains(index) else {
            return
        }

        rows[index].tapCommand.execute()
    }
}
