// Created by Egor Shkarin 23.03.2026

import UIKit
import SnapKit

final class MainExpensesSectionView: UIView, LayoutScaleProviding {
    private enum Constants {
        static let headerReuseId = "MainExpensesSectionHeaderView"
    }
    
    private enum LayoutState {
        case content
        case empty
        case error
    }
    
    private var itemHeight: CGFloat { sizeXL }
    private var itemSpacing: CGFloat { spaceS }
    private var sectionHeaderHeight: CGFloat { sizeM }
    private var sectionSpacing: CGFloat { spaceS }

    private var viewModel: ViewModel = .init()

    private let titleLabel = Label()
    private let seeAllButton = UIButton(type: .system)
    private let errorView = FullScreenCommonErrorView()
    private let emptyLabel = Label()
    private let loadingView = UIActivityIndicatorView(style: .medium)

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = itemSpacing
        layout.sectionInset = .zero
        layout.headerReferenceSize = CGSize(width: 0, height: sectionHeaderHeight)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.isScrollEnabled = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            ExpenseCollectionViewCell.self,
            forCellWithReuseIdentifier: ExpenseCollectionViewCell.reuseId
        )
        collectionView.register(
            MainExpensesSectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: Constants.headerReuseId
        )

        return collectionView
    }()

    private var collectionHeightConstraint: Constraint?
    private var collectionBottomConstraint: Constraint?
    private var errorBottomConstraint: Constraint?
    private var emptyBottomConstraint: Constraint?

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

private extension MainExpensesSectionView {
    func setupViews() {
        backgroundColor = .clear

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
        let height = viewModel.sections.enumerated().reduce(CGFloat.zero) { result, element in
            let index = element.offset
            let section = element.element

            let rowsCount = CGFloat(section.items.count)
            let rowsHeight = rowsCount * itemHeight
            let rowsSpacing = max(CGFloat.zero, rowsCount - 1) * itemSpacing
            let interSectionSpacing = index < (viewModel.sections.count - 1)
                ? sectionSpacing
                : CGFloat.zero

            return result + sectionHeaderHeight + rowsHeight + rowsSpacing + interSectionSpacing
        }

        collectionHeightConstraint?.update(offset: height)
    }

    func updateItemSize() {
        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
            return
        }

        let width = max(.zero, collectionView.bounds.width)
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

extension MainExpensesSectionView: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        viewModel.sections.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.sections[section].items.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ExpenseCollectionViewCell.reuseId,
            for: indexPath
        ) as? ExpenseCollectionViewCell else {
            return UICollectionViewCell()
        }

        cell.configure(with: viewModel.sections[indexPath.section].items[indexPath.item])
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader,
              let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: Constants.headerReuseId,
                for: indexPath
              ) as? MainExpensesSectionHeaderView
        else {
            return UICollectionReusableView()
        }

        header.configure(with: viewModel.sections[indexPath.section].title)
        return header
    }
}

extension MainExpensesSectionView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.sections[indexPath.section].items[indexPath.item].tapCommand.execute()
    }
}

extension MainExpensesSectionView {
    struct SectionViewModel: Equatable {
        let title: Label.LabelViewModel
        let items: [ExpenseView.ViewModel]

        init(
            title: Label.LabelViewModel = .init(),
            items: [ExpenseView.ViewModel] = []
        ) {
            self.title = title
            self.items = items
        }
    }

    struct ViewModel: Equatable {
        let title: Label.LabelViewModel
        let seeAllTitle: Label.LabelViewModel
        let seeAllCommand: Command
        let isLoading: Bool
        let emptyText: String?
        let errorViewModel: FullScreenCommonErrorView.ViewModel?
        let sections: [SectionViewModel]

        init(
            title: Label.LabelViewModel = .init(),
            seeAllTitle: Label.LabelViewModel = .init(),
            seeAllCommand: Command = .nope,
            isLoading: Bool = false,
            emptyText: String? = nil,
            errorViewModel: FullScreenCommonErrorView.ViewModel? = nil,
            sections: [SectionViewModel] = []
        ) {
            self.title = title
            self.seeAllTitle = seeAllTitle
            self.seeAllCommand = seeAllCommand
            self.isLoading = isLoading
            self.emptyText = emptyText
            self.errorViewModel = errorViewModel
            self.sections = sections
        }
    }
}

private final class MainExpensesSectionHeaderView: UICollectionReusableView {
    private let titleLabel = Label()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with viewModel: Label.LabelViewModel) {
        titleLabel.apply(viewModel)
    }
}
