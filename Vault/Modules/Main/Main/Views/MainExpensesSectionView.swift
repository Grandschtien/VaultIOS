// Created by Egor Shkarin 23.03.2026

import UIKit
import SnapKit

final class MainExpensesSectionView: UIView, LayoutScaleProviding {
    private enum Constants {
        static let headerReuseId = "MainExpensesSectionHeaderView"
    }
    
    private enum ContentState {
        case loading
        case content
        case empty
        case error
    }
    
    private var itemHeight: CGFloat { 72 }
    private var itemSpacing: CGFloat { spaceS }
    private var sectionHeaderHeight: CGFloat { sizeM }
    private var sectionSpacing: CGFloat { spaceS }

    private var viewModel: ViewModel = .init()

    private let titleLabel = Label()
    private let seeAllButton = UIButton(type: .system)
    private let contentStackView = UIStackView()
    private let errorView = FullScreenCommonErrorView()
    private let emptyLabel = Label()
    private let loadingView = MainExpensesLoadingView()

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
        collectionView.register(BaseCollectionViewCellWrapper<ExpenseView>.self)
        collectionView.register(
            MainExpensesSectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: Constants.headerReuseId
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

        titleLabel.apply(viewModel.title)
        seeAllButton.setTitle(viewModel.seeAllTitle.text, for: .normal)
        seeAllButton.titleLabel?.font = viewModel.seeAllTitle.font
        seeAllButton.setTitleColor(viewModel.seeAllTitle.textColor, for: .normal)

        switch viewModel.state {
        case .loading:
            loadingView.showLoading()
            applyState(.loading)
            collectionHeightConstraint?.update(offset: 0)
        case let .error(errorViewModel):
            loadingView.hideLoading()
            errorView.apply(errorViewModel)
            applyState(.error)
            collectionHeightConstraint?.update(offset: 0)
        case let .empty(emptyText):
            loadingView.hideLoading()
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
            applyState(.empty)
            collectionHeightConstraint?.update(offset: 0)
        case .loaded:
            loadingView.hideLoading()
            applyState(.content)
            collectionView.reloadData()
            updateCollectionHeight()
        }
    }
}

private extension MainExpensesSectionView {
    func setupViews() {
        backgroundColor = .clear
        contentStackView.axis = .vertical
        contentStackView.alignment = .fill
        contentStackView.distribution = .fill
        contentStackView.spacing = .zero

        seeAllButton.contentHorizontalAlignment = .right
        seeAllButton.addTarget(self, action: #selector(handleTapSeeAll), for: .touchUpInside)

        errorView.isHidden = true
        emptyLabel.isHidden = true
        loadingView.isHidden = true
    }

    func setupLayout() {
        addSubview(titleLabel)
        addSubview(seeAllButton)
        addSubview(contentStackView)
        [loadingView, emptyLabel, collectionView, errorView].forEach { contentStackView.addArrangedSubview($0) }

        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
        }

        seeAllButton.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.trailing.equalToSuperview()
        }

        contentStackView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(spaceS)
            make.leading.trailing.bottom.equalToSuperview()
        }

        collectionView.snp.makeConstraints { make in
            collectionHeightConstraint = make.height.equalTo(0).constraint
        }
        
        applyState(.content)
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
    
    private func applyState(_ state: ContentState) {
        switch state {
        case .loading:
            loadingView.isHidden = false
            errorView.isHidden = true
            emptyLabel.isHidden = true
            collectionView.isHidden = true
        case .content:
            loadingView.isHidden = true
            errorView.isHidden = true
            emptyLabel.isHidden = true
            collectionView.isHidden = false
        case .empty:
            loadingView.isHidden = true
            errorView.isHidden = true
            emptyLabel.isHidden = false
            collectionView.isHidden = true
        case .error:
            loadingView.isHidden = true
            errorView.isHidden = false
            emptyLabel.isHidden = true
            collectionView.isHidden = true
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
        let cell = collectionView.dequeueReusableCell(BaseCollectionViewCellWrapper<ExpenseView>.self, for: indexPath)
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
    enum State: Equatable {
        case loading
        case empty(text: String)
        case loaded(content: [SectionViewModel])
        case error(FullScreenCommonErrorView.ViewModel)
    }

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
        let state: State

        init(
            title: Label.LabelViewModel = .init(),
            seeAllTitle: Label.LabelViewModel = .init(),
            seeAllCommand: Command = .nope,
            state: State = .loading
        ) {
            self.title = title
            self.seeAllTitle = seeAllTitle
            self.seeAllCommand = seeAllCommand
            self.state = state
        }
    }
}

private extension MainExpensesSectionView.ViewModel {
    var sections: [MainExpensesSectionView.SectionViewModel] {
        if case let .loaded(content) = state {
            return content
        }

        return []
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
