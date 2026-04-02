import UIKit
import SnapKit

final class ProfileCurrencyView: UIView, LayoutScaleProviding {
    private let tableAdapter: ProfileCurrencyTableAdapter

    private let searchField = TextField()
    private let tableView = UITableView(frame: .zero, style: .plain)

    init(
        frame: CGRect = .zero,
        tableAdapter: ProfileCurrencyTableAdapter
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
}

extension ProfileCurrencyView {
    func configure(with viewModel: ProfileCurrencyViewModel) {
        searchField.apply(viewModel.searchField)
        tableAdapter.configure(rows: viewModel.rows)
    }
}

private extension ProfileCurrencyView {
    func setupViews() {
        backgroundColor = Asset.Colors.backgroundPrimary.color

        tableAdapter.attach(to: tableView)
        tableView.sectionHeaderTopPadding = .zero
        tableView.contentInset = UIEdgeInsets(
            top: spaceS,
            left: .zero,
            bottom: spaceS,
            right: .zero
        )
    }

    func setupLayout() {
        addSubview(searchField)
        addSubview(tableView)

        searchField.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide).offset(spaceS)
            make.horizontalEdges.equalTo(safeAreaLayoutGuide).inset(spaceS)
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(searchField.snp.bottom).offset(spaceS)
            make.horizontalEdges.equalTo(safeAreaLayoutGuide).inset(spaceS)
            make.bottom.equalTo(safeAreaLayoutGuide)
        }
    }
}
