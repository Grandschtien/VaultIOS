import UIKit
import SnapKit

final class ExpenseCategoryPickerView: UIView, LayoutScaleProviding {
    private var viewModel: ExpenseCategoryPickerViewModel = .init()
    private let tableAdapter: ExpenseCategoryPickerTableAdapter

    private let headerView = AddExpenseSheetHeaderView()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let errorView = FullScreenCommonErrorView()
    private let emptyLabel = Label()
    private let addButton = Button()

    init(
        frame: CGRect = .zero,
        tableAdapter: ExpenseCategoryPickerTableAdapter
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

    func configure(with viewModel: ExpenseCategoryPickerViewModel) {
        self.viewModel = viewModel

        headerView.apply(viewModel.header)
        addButton.apply(viewModel.addButton)

        switch viewModel.state {
        case let .error(errorViewModel):
            errorView.isHidden = false
            emptyLabel.isHidden = true
            tableView.isHidden = true
            errorView.apply(errorViewModel)
            tableAdapter.configure(rows: [])
        case let .empty(labelViewModel):
            errorView.isHidden = true
            emptyLabel.isHidden = false
            tableView.isHidden = true
            emptyLabel.apply(labelViewModel)
            tableAdapter.configure(rows: [])
        case let .loading(rows), let .loaded(rows):
            errorView.isHidden = true
            emptyLabel.isHidden = true
            tableView.isHidden = false
            tableAdapter.configure(rows: rows)
            tableView.reloadData()
        }
    }
}

private extension ExpenseCategoryPickerView {
    func setupViews() {
        backgroundColor = Asset.Colors.backgroundPrimary.color

        tableAdapter.output = self
        tableAdapter.attach(to: tableView)

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.sectionHeaderTopPadding = .zero
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = sizeXL

        errorView.isHidden = true
        emptyLabel.isHidden = true
    }

    func setupLayout() {
        addSubview(headerView)
        addSubview(tableView)
        addSubview(errorView)
        addSubview(emptyLabel)
        addSubview(addButton)

        headerView.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide)
            make.horizontalEdges.equalToSuperview()
        }

        addButton.snp.makeConstraints { make in
            make.horizontalEdges.equalTo(safeAreaLayoutGuide).inset(spaceS)
            make.bottom.equalTo(safeAreaLayoutGuide).inset(spaceS)
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(spaceS)
            make.horizontalEdges.equalTo(safeAreaLayoutGuide).inset(spaceS)
            make.bottom.equalTo(addButton.snp.top).offset(-spaceS)
        }

        errorView.snp.makeConstraints { make in
            make.edges.equalTo(tableView)
        }

        emptyLabel.snp.makeConstraints { make in
            make.center.equalTo(tableView)
            make.horizontalEdges.equalTo(tableView).inset(spaceS)
        }
    }

    func rows(from state: ExpenseCategoryPickerViewModel.State) -> [ExpenseCategoryPickerViewModel.RowViewModel] {
        switch state {
        case .error, .empty:
            return []
        case let .loading(rows), let .loaded(rows):
            return rows
        }
    }

    func contentHeight(for width: CGFloat) -> CGFloat {
        switch viewModel.state {
        case .error:
            return errorView.systemLayoutSizeFitting(
                CGSize(
                    width: errorView.bounds.width > .zero ? errorView.bounds.width : width,
                    height: UIView.layoutFittingCompressedSize.height
                ),
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel
            ).height
        case .empty:
            return max(
                emptyLabel.systemLayoutSizeFitting(
                    CGSize(
                        width: emptyLabel.bounds.width > .zero ? emptyLabel.bounds.width : width,
                        height: UIView.layoutFittingCompressedSize.height
                    ),
                    withHorizontalFittingPriority: .required,
                    verticalFittingPriority: .fittingSizeLevel
                ).height,
                sizeXL
            )
        case .loading, .loaded:
            tableView.layoutIfNeeded()
            return tableView.contentSize.height
        }
    }
}

extension ExpenseCategoryPickerView: AddExpenseSheetContentHeightProviding {
    func preferredContentHeight(for width: CGFloat) -> CGFloat {
        layoutIfNeeded()

        let headerHeight = headerView.systemLayoutSizeFitting(
            CGSize(
                width: headerView.bounds.width > .zero ? headerView.bounds.width : width,
                height: UIView.layoutFittingCompressedSize.height
            ),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height

        let buttonHeight = addButton.systemLayoutSizeFitting(
            CGSize(
                width: addButton.bounds.width > .zero ? addButton.bounds.width : width,
                height: UIView.layoutFittingCompressedSize.height
            ),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height

        return safeAreaInsets.top
            + headerHeight
            + spaceS
            + contentHeight(for: width)
            + spaceS
            + buttonHeight
            + safeAreaInsets.bottom
    }
}

extension ExpenseCategoryPickerView: ExpenseCategoryPickerTableAdapterOutput {
    func handleDidSelectCategoryRow(at index: Int) {
        let rows = rows(from: viewModel.state)
        guard rows.indices.contains(index) else {
            return
        }

        rows[index].tapCommand.execute()
    }
}
