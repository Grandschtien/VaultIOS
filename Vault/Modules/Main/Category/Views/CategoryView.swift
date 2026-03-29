// Created by Egor Shkarin on 28.03.2026

import UIKit
import SnapKit

final class CategoryView: UIView, LayoutScaleProviding {
    private var viewModel: CategoryViewModel = .init()
    private let collectionAdapter: CategoryExpensesCollectionViewAdapter

    private let errorView = FullScreenCommonErrorView()
    private let emptyLabel = Label()
    private let paginationSpinner = UIActivityIndicatorView(style: .medium)

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.contentInset = UIEdgeInsets(
            top: .zero,
            left: .zero,
            bottom: sizeL,
            right: .zero
        )
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = sizeXL
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = sizeM

        return tableView
    }()

    init(
        frame: CGRect = .zero,
        collectionAdapter: CategoryExpensesCollectionViewAdapter
    ) {
        self.collectionAdapter = collectionAdapter
        super.init(frame: frame)
        setupViews()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CategoryView {
    func configure(with viewModel: CategoryViewModel) {
        self.viewModel = viewModel
        let content = viewModel.content

        collectionAdapter.configure(
            summary: content.summary,
            sections: sections(from: content.state),
            hasMore: content.hasMore,
            isLoadingNextPage: content.isLoadingNextPage
        )

        switch content.state {
        case let .failed(errorViewModel):
            errorView.isHidden = false
            errorView.apply(errorViewModel)
            tableView.isHidden = true
            emptyLabel.isHidden = true
            paginationSpinner.stopAnimating()
        case .loading:
            errorView.isHidden = true
            tableView.isHidden = false
            emptyLabel.isHidden = true
            paginationSpinner.stopAnimating()
        case .loaded:
            errorView.isHidden = true
            tableView.isHidden = false
            emptyLabel.isHidden = true

            if content.isLoadingNextPage {
                paginationSpinner.startAnimating()
            } else {
                paginationSpinner.stopAnimating()
            }
        case let .empty(text):
            errorView.isHidden = true
            tableView.isHidden = false
            emptyLabel.isHidden = false
            emptyLabel.apply(
                .init(
                    text: text,
                    font: Typography.typographyMedium14,
                    textColor: Asset.Colors.textAndIconPlaceseholder.color,
                    alignment: .left
                )
            )
            paginationSpinner.stopAnimating()
        }
        
        setNeedsLayout()
    }
}

private extension CategoryView {
    func sections(
        from state: CategoryViewModel.ContentViewModel.State
    ) -> [CategoryViewModel.SectionViewModel] {
        switch state {
        case let .loading(sections), let .loaded(sections):
            return sections
        case .failed, .empty:
            return []
        }
    }

    func setupViews() {
        backgroundColor = Asset.Colors.backgroundPrimary.color

        collectionAdapter.output = self
        collectionAdapter.attach(to: tableView)

        errorView.isHidden = true
        emptyLabel.isHidden = true
        paginationSpinner.hidesWhenStopped = true
        paginationSpinner.color = Asset.Colors.interactiveElemetsPrimary.color
    }

    func setupLayout() {
        addSubview(tableView)
        addSubview(errorView)
        addSubview(emptyLabel)
        addSubview(paginationSpinner)

        tableView.snp.makeConstraints { make in
            make.top.bottom.equalTo(safeAreaLayoutGuide)
            make.leading.trailing.equalTo(safeAreaLayoutGuide).inset(spaceS)
        }

        errorView.snp.makeConstraints { make in
            make.edges.equalTo(tableView)
        }

        emptyLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        paginationSpinner.snp.makeConstraints { make in
            make.centerX.equalTo(tableView.snp.centerX)
            make.bottom.equalTo(safeAreaLayoutGuide).inset(spaceS)
        }
    }
}

extension CategoryView: CategoryExpensesCollectionViewAdapterOutput {
    func handleNeedLoadNextPage() {
        viewModel.loadNextPageCommand.execute()
    }
}
