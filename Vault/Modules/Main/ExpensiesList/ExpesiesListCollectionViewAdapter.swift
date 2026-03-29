// Created by Egor Shkarin on 25.03.2026

import UIKit
import SnapKit

protocol ExpesiesListCollectionViewAdapterOutput: AnyObject {
    func handleNeedLoadNextPage()
}

final class ExpesiesListCollectionViewAdapter: NSObject {
    private enum Constants {
        static let headerReuseId = "ExpesiesListSectionHeaderView"
    }

    weak var output: ExpesiesListCollectionViewAdapterOutput?

    private var sections: [ExpesiesListViewModel.SectionViewModel] = []
    private var hasMore: Bool = false
    private var isLoadingNextPage: Bool = false

    func attach(to collectionView: UICollectionView) {
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            ExpenseCollectionViewCell.self,
            forCellWithReuseIdentifier: ExpenseCollectionViewCell.reuseId
        )
        collectionView.register(
            ExpesiesListSectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: Constants.headerReuseId
        )
    }

    func configure(
        sections: [ExpesiesListViewModel.SectionViewModel],
        hasMore: Bool,
        isLoadingNextPage: Bool
    ) {
        self.sections = sections
        self.hasMore = hasMore
        self.isLoadingNextPage = isLoadingNextPage
    }
}

private extension ExpesiesListCollectionViewAdapter {
    func shouldRequestNextPage(for indexPath: IndexPath) -> Bool {
        guard hasMore, !isLoadingNextPage else {
            return false
        }

        guard let lastSection = sections.indices.last else {
            return false
        }

        guard let lastItem = sections[lastSection].items.indices.last else {
            return false
        }

        return indexPath.section == lastSection && indexPath.item == lastItem
    }
}

extension ExpesiesListCollectionViewAdapter: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        sections.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        sections[section].items.count
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

        cell.configure(with: sections[indexPath.section].items[indexPath.item])
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
              ) as? ExpesiesListSectionHeaderView
        else {
            return UICollectionReusableView()
        }

        header.configure(with: sections[indexPath.section].title)
        return header
    }
}

extension ExpesiesListCollectionViewAdapter: UICollectionViewDelegate {
    func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        guard shouldRequestNextPage(for: indexPath) else {
            return
        }

        output?.handleNeedLoadNextPage()
    }
}

private final class ExpesiesListSectionHeaderView: UICollectionReusableView {
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
