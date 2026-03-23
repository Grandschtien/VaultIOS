// Created by Egor Shkarin 23.03.2026

import UIKit
import SnapKit

final class MainCategoriesSectionView: UIView, LayoutScaleProviding {
    private var itemHeight: CGFloat { sizeXL * 2 }
    private var itemSpacing: CGFloat { spaceS }
    private var columns: CGFloat { 2 }

    private var viewModel: ViewModel = .init()
    private var items: [CategoryCollectionViewCell.ViewModel] = []

    private let titleLabel = Label()
    private let seeAllButton = UIButton(type: .system)
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
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            CategoryCollectionViewCell.self,
            forCellWithReuseIdentifier: CategoryCollectionViewCell.reuseId
        )

        return collectionView
    }()

    private var collectionHeightConstraint: Constraint?

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

    func configure(with viewModel: ViewModel) {
        self.viewModel = viewModel
        self.items = viewModel.items

        titleLabel.apply(viewModel.title)
        seeAllButton.setTitle(viewModel.seeAllTitle.text, for: .normal)
        seeAllButton.titleLabel?.font = viewModel.seeAllTitle.font
        seeAllButton.setTitleColor(viewModel.seeAllTitle.textColor, for: .normal)

        loadingView.isHidden = true
        loadingView.stopAnimating()

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
        } else {
            emptyLabel.isHidden = true
        }

        collectionView.reloadData()
        updateCollectionHeight()
    }
}

private extension MainCategoriesSectionView {
    func setupViews() {
        backgroundColor = .clear

        seeAllButton.contentHorizontalAlignment = .right
        seeAllButton.addTarget(self, action: #selector(handleTapSeeAll), for: .touchUpInside)

        emptyLabel.isHidden = true
        loadingView.hidesWhenStopped = true
    }

    func setupLayout() {
        [titleLabel, seeAllButton, loadingView, emptyLabel, collectionView].forEach {
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
        }

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(spaceS)
            make.leading.trailing.equalToSuperview()
            collectionHeightConstraint = make.height.equalTo(0).constraint
            make.bottom.equalToSuperview()
        }
    }

    @objc
    func handleTapSeeAll() {
        viewModel.seeAllCommand.execute()
    }

    func updateCollectionHeight() {
        let rowsCount = ceil(CGFloat(items.count) / columns)
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
}

extension MainCategoriesSectionView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: CategoryCollectionViewCell.reuseId,
            for: indexPath
        ) as? CategoryCollectionViewCell else {
            return UICollectionViewCell()
        }

        cell.configure(with: items[indexPath.item])
        return cell
    }
}

extension MainCategoriesSectionView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        items[indexPath.item].tapCommand.execute()
    }
}

extension MainCategoriesSectionView {
    struct ViewModel: Equatable {
        let title: Label.LabelViewModel
        let seeAllTitle: Label.LabelViewModel
        let seeAllCommand: Command
        let isLoading: Bool
        let emptyText: String?
        let items: [CategoryCollectionViewCell.ViewModel]

        init(
            title: Label.LabelViewModel = .init(),
            seeAllTitle: Label.LabelViewModel = .init(),
            seeAllCommand: Command = .nope,
            isLoading: Bool = false,
            emptyText: String? = nil,
            items: [CategoryCollectionViewCell.ViewModel] = []
        ) {
            self.title = title
            self.seeAllTitle = seeAllTitle
            self.seeAllCommand = seeAllCommand
            self.isLoading = isLoading
            self.emptyText = emptyText
            self.items = items
        }
    }
}
