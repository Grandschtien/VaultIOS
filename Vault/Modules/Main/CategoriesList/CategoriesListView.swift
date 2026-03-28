// Created by Codex on 27.03.2026

import UIKit
import SnapKit

final class CategoriesListView: UIView, LayoutScaleProviding {
    private var itemHeight: CGFloat { sizeXXL }
    private var itemSpacing: CGFloat { spaceS }
    private var columns: CGFloat { 2 }

    private var viewModel: CategoriesListViewModel = .init()
    private let collectionAdapter: CategoryCollectionViewAdapter

    private let errorView = FullScreenCommonErrorView()
    private let emptyLabel = Label()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = itemSpacing
        layout.minimumLineSpacing = itemSpacing

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false

        return collectionView
    }()

    init(
        frame: CGRect = .zero,
        collectionAdapter: CategoryCollectionViewAdapter
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

    override func layoutSubviews() {
        super.layoutSubviews()
        updateItemSize()
    }
}

extension CategoriesListView {
    func configure(with viewModel: CategoriesListViewModel) {
        self.viewModel = viewModel

        switch viewModel.state {
        case let .error(errorViewModel):
            errorView.isHidden = false
            errorView.apply(errorViewModel)
            collectionView.isHidden = true
            emptyLabel.isHidden = true
            collectionAdapter.configure(items: [])
        case let .loading(items):
            errorView.isHidden = true
            collectionView.isHidden = false
            emptyLabel.isHidden = true
            collectionAdapter.configure(items: items)
        case let .empty(text):
            errorView.isHidden = true
            collectionView.isHidden = false
            emptyLabel.isHidden = false
            emptyLabel.apply(
                .init(
                    text: text,
                    font: Typography.typographyMedium14,
                    textColor: Asset.Colors.textAndIconPlaceseholder.color,
                    alignment: .left,
                    numberOfLines: 0,
                    lineBreakMode: .byWordWrapping
                )
            )
            collectionAdapter.configure(items: [])
        case let .loaded(items):
            errorView.isHidden = true
            collectionView.isHidden = false
            emptyLabel.isHidden = true
            collectionAdapter.configure(items: items)
        }

        collectionView.reloadData()
    }
}

private extension CategoriesListView {
    func setupViews() {
        backgroundColor = Asset.Colors.backgroundPrimary.color
        collectionAdapter.output = self
        collectionAdapter.attach(to: collectionView)

        errorView.isHidden = true
        emptyLabel.isHidden = true
    }

    func setupLayout() {
        addSubview(collectionView)
        addSubview(errorView)
        addSubview(emptyLabel)

        collectionView.snp.makeConstraints { make in
            make.verticalEdges.equalTo(safeAreaLayoutGuide)
            make.horizontalEdges.equalTo(safeAreaLayoutGuide).inset(spaceS)
        }

        errorView.snp.makeConstraints { make in
            make.edges.equalTo(collectionView)
        }

        emptyLabel.snp.makeConstraints { make in
            make.top.equalTo(collectionView.snp.top).offset(spaceS)
            make.leading.trailing.equalTo(collectionView)
        }
    }

    func updateItemSize() {
        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
            return
        }

        let availableWidth = max(
            .zero,
            collectionView.bounds.width - itemSpacing
        )

        let width = floor(availableWidth / columns)
        layout.itemSize = CGSize(width: width, height: itemHeight)
    }

    func items(from state: CategoriesListViewModel.State) -> [CategoryCollectionViewCell.ViewModel] {
        switch state {
        case .error, .empty:
            return []
        case let .loading(items):
            return items
        case let .loaded(items):
            return items
        }
    }
}

extension CategoriesListView: CategoryCollectionViewAdapterOutput {
    func handleDidSelectCategoryItem(at index: Int) {
        let items = items(from: viewModel.state)
        guard items.indices.contains(index) else {
            return
        }

        items[index].tapCommand.execute()
    }
}
