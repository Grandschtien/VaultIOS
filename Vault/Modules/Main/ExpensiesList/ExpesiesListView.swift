// Created by Egor Shkarin 25.03.2026

import UIKit
import SnapKit

final class ExpesiesListView: UIView, LayoutScaleProviding {
    private var itemHeight: CGFloat { 72 }
    private var itemSpacing: CGFloat { spaceS }
    private var sectionHeaderHeight: CGFloat { sizeM }

    private var viewModel: ExpesiesListViewModel = .init()
    private let collectionAdapter = ExpesiesListCollectionViewAdapter()

    private let errorView = FullScreenCommonErrorView()
    private let emptyLabel = Label()
    private let loadingView = ExpensiesListLoadingView()
    private let paginationSpinner = UIActivityIndicatorView(style: .medium)

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = .zero
        layout.minimumLineSpacing = itemSpacing
        layout.sectionInset = .zero
        layout.headerReferenceSize = CGSize(width: .zero, height: sectionHeaderHeight)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.contentInset = UIEdgeInsets(
            top: .zero,
            left: .zero,
            bottom: sizeL,
            right: .zero
        )

        return collectionView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateItemSize()
    }
}

extension ExpesiesListView {
    func configure(with viewModel: ExpesiesListViewModel) {
        self.viewModel = viewModel

        switch viewModel.state {
        case let .error(errorViewModel):
            loadingView.hideLoading()
            loadingView.isHidden = true
            errorView.isHidden = false
            errorView.apply(errorViewModel)
            collectionView.isHidden = true
            emptyLabel.isHidden = true
            paginationSpinner.stopAnimating()
            collectionAdapter.configure(
                sections: [],
                hasMore: false,
                isLoadingNextPage: false
            )

        case .loading:
            loadingView.isHidden = false
            loadingView.showLoading()
            errorView.isHidden = true
            collectionView.isHidden = true
            emptyLabel.isHidden = true
            paginationSpinner.stopAnimating()
            collectionAdapter.configure(
                sections: [],
                hasMore: false,
                isLoadingNextPage: false
            )

        case let .empty(text):
            loadingView.hideLoading()
            loadingView.isHidden = true
            errorView.isHidden = true
            collectionView.isHidden = false
            emptyLabel.isHidden = false
            emptyLabel.apply(
                .init(
                    text: text,
                    font: Typography.typographyMedium14,
                    textColor: Asset.Colors.textAndIconPlaceseholder.color,
                    alignment: .left,
                    numberOfLines: .zero
                )
            )
            paginationSpinner.stopAnimating()
            collectionAdapter.configure(
                sections: [],
                hasMore: false,
                isLoadingNextPage: false
            )

        case let .loaded(content):
            loadingView.hideLoading()
            loadingView.isHidden = true
            errorView.isHidden = true
            collectionView.isHidden = false
            emptyLabel.isHidden = true

            if content.isLoadingNextPage {
                paginationSpinner.startAnimating()
            } else {
                paginationSpinner.stopAnimating()
            }

            collectionAdapter.configure(
                sections: content.sections,
                hasMore: content.hasMore,
                isLoadingNextPage: content.isLoadingNextPage
            )
        }

        collectionView.reloadData()
    }
}

private extension ExpesiesListView {
    func setupViews() {
        backgroundColor = Asset.Colors.backgroundPrimary.color
        collectionAdapter.output = self
        collectionAdapter.attach(to: collectionView)
        errorView.isHidden = true
        emptyLabel.isHidden = true
        loadingView.isHidden = true
        paginationSpinner.hidesWhenStopped = true
        paginationSpinner.color = Asset.Colors.interactiveElemetsPrimary.color
    }

    func setupLayout() {
        addSubview(collectionView)
        addSubview(loadingView)
        addSubview(errorView)
        addSubview(emptyLabel)
        addSubview(paginationSpinner)

        collectionView.snp.makeConstraints { make in
            make.verticalEdges.equalTo(safeAreaLayoutGuide)
            make.horizontalEdges.equalTo(safeAreaLayoutGuide).inset(spaceS)
        }

        errorView.snp.makeConstraints { make in
            make.edges.equalTo(collectionView)
        }

        loadingView.snp.makeConstraints { make in
            make.edges.equalTo(collectionView)
        }

        emptyLabel.snp.makeConstraints { make in
            make.top.equalTo(collectionView.snp.top).offset(spaceS)
            make.leading.trailing.equalTo(collectionView)
        }

        paginationSpinner.snp.makeConstraints { make in
            make.centerX.equalTo(collectionView.snp.centerX)
            make.bottom.equalTo(safeAreaLayoutGuide).inset(spaceS)
        }
    }

    func updateItemSize() {
        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
            return
        }

        layout.itemSize = CGSize(
            width: max(.zero, collectionView.bounds.width),
            height: itemHeight
        )
    }
}

extension ExpesiesListView: ExpesiesListCollectionViewAdapterOutput {
    func handleNeedLoadNextPage() {
        viewModel.loadNextPageCommand.execute()
    }
}
