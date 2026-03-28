// Created by Egor Shkarin 23.03.2026

import UIKit
import SnapKit

final class MainCategoriesSectionView: UIView, LayoutScaleProviding {
    private var itemHeight: CGFloat { sizeXXL }
    private var itemSpacing: CGFloat { spaceS }
    private var columns: CGFloat { 2 }
    
    private enum LayoutState {
        case content
        case empty
        case error
    }

    private var viewModel: ViewModel = .init()
    private let collectionAdapter: CategoryCollectionViewAdapter

    private let titleLabel = Label()
    private let seeAllButton = UIButton(type: .system)
    private let errorView = FullScreenCommonErrorView()
    private let emptyLabel = Label()
    private let loadingView = UIActivityIndicatorView(style: .medium)

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = itemSpacing
        layout.minimumLineSpacing = itemSpacing

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.isScrollEnabled = false

        return collectionView
    }()

    private var collectionHeightConstraint: Constraint?
    private var collectionBottomConstraint: Constraint?
    private var errorBottomConstraint: Constraint?
    private var emptyBottomConstraint: Constraint?

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

    func configure(with viewModel: ViewModel) {
        self.viewModel = viewModel
        collectionAdapter.configure(items: viewModel.items)

        titleLabel.apply(viewModel.title)
        seeAllButton.setTitle(viewModel.seeAllTitle.text, for: .normal)
        seeAllButton.titleLabel?.font = viewModel.seeAllTitle.font
        seeAllButton.setTitleColor(viewModel.seeAllTitle.textColor, for: .normal)

        loadingView.isHidden = true
        loadingView.stopAnimating()

        if let errorViewModel = viewModel.errorViewModel {
            errorView.isHidden = false
            errorView.apply(errorViewModel)
            emptyLabel.isHidden = true
            collectionView.isHidden = true
            collectionHeightConstraint?.update(offset: 0)
            applyLayoutState(.error)
            return
        }

        errorView.isHidden = true

        if let emptyText = viewModel.emptyText {
            emptyLabel.isHidden = false
            emptyLabel.apply(
                .init(
                    text: emptyText,
                    font: Typography.typographyMedium14,
                    textColor: Asset.Colors.textAndIconPlaceseholder.color,
                    alignment: .left,
                    numberOfLines: 0,
                    lineBreakMode: .byWordWrapping
                )
            )
            collectionView.isHidden = true
            collectionHeightConstraint?.update(offset: 0)
            applyLayoutState(.empty)
            return
        } else {
            emptyLabel.isHidden = true
        }

        collectionView.isHidden = false
        collectionView.reloadData()
        updateCollectionHeight()
        applyLayoutState(.content)
    }
}

private extension MainCategoriesSectionView {
    func setupViews() {
        backgroundColor = .clear
        collectionAdapter.output = self
        collectionAdapter.attach(to: collectionView)

        seeAllButton.contentHorizontalAlignment = .right
        seeAllButton.addTarget(self, action: #selector(handleTapSeeAll), for: .touchUpInside)

        errorView.isHidden = true
        emptyLabel.isHidden = true
        loadingView.hidesWhenStopped = true
    }

    func setupLayout() {
        [titleLabel, seeAllButton, loadingView, emptyLabel, collectionView, errorView].forEach {
            addSubview($0)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
        }

        seeAllButton.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.trailing.equalToSuperview()
        }

        loadingView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(spaceS)
            make.leading.equalToSuperview()
        }

        emptyLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(spaceS)
            make.leading.trailing.equalToSuperview()
            emptyBottomConstraint = make.bottom.equalToSuperview().constraint
        }

        errorView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(spaceS)
            make.leading.trailing.equalToSuperview()
            errorBottomConstraint = make.bottom.equalToSuperview().constraint
        }

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(spaceS)
            make.leading.trailing.equalToSuperview()
            collectionHeightConstraint = make.height.equalTo(0).constraint
            collectionBottomConstraint = make.bottom.equalToSuperview().constraint
        }
        
        applyLayoutState(.content)
    }

    @objc
    func handleTapSeeAll() {
        viewModel.seeAllCommand.execute()
    }

    func updateCollectionHeight() {
        let rowsCount = ceil(CGFloat(viewModel.items.count) / columns)
        let rowsHeight = rowsCount * itemHeight
        let spacingHeight = max(.zero, rowsCount - 1) * itemSpacing

        collectionHeightConstraint?.update(offset: rowsHeight + spacingHeight)
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
    
    private func applyLayoutState(_ state: LayoutState) {
        collectionBottomConstraint?.deactivate()
        errorBottomConstraint?.deactivate()
        emptyBottomConstraint?.deactivate()
        
        switch state {
        case .content:
            collectionBottomConstraint?.activate()
        case .empty:
            emptyBottomConstraint?.activate()
        case .error:
            errorBottomConstraint?.activate()
        }
    }
}

extension MainCategoriesSectionView: CategoryCollectionViewAdapterOutput {
    func handleDidSelectCategoryItem(at index: Int) {
        guard viewModel.items.indices.contains(index) else {
            return
        }

        viewModel.items[index].tapCommand.execute()
    }
}

extension MainCategoriesSectionView {
    struct ViewModel: Equatable {
        let title: Label.LabelViewModel
        let seeAllTitle: Label.LabelViewModel
        let seeAllCommand: Command
        let isLoading: Bool
        let emptyText: String?
        let errorViewModel: FullScreenCommonErrorView.ViewModel?
        let items: [CategoryCollectionViewCell.ViewModel]

        init(
            title: Label.LabelViewModel = .init(),
            seeAllTitle: Label.LabelViewModel = .init(),
            seeAllCommand: Command = .nope,
            isLoading: Bool = false,
            emptyText: String? = nil,
            errorViewModel: FullScreenCommonErrorView.ViewModel? = nil,
            items: [CategoryCollectionViewCell.ViewModel] = []
        ) {
            self.title = title
            self.seeAllTitle = seeAllTitle
            self.seeAllCommand = seeAllCommand
            self.isLoading = isLoading
            self.emptyText = emptyText
            self.errorViewModel = errorViewModel
            self.items = items
        }
    }
}
