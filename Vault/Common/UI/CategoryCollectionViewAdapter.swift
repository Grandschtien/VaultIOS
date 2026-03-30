// Created by Egor Shkarin on 27.03.2026

import UIKit

protocol CategoryCollectionViewAdapterOutput: AnyObject {
    func handleDidSelectCategoryItem(at index: Int)
}

final class CategoryCollectionViewAdapter: NSObject {
    weak var output: CategoryCollectionViewAdapterOutput?

    private var items: [CategoryCollectionViewCell.ViewModel] = []

    func attach(to collectionView: UICollectionView) {
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(CategoryCollectionViewCell.self)
    }

    func configure(items: [CategoryCollectionViewCell.ViewModel]) {
        self.items = items
    }
}

extension CategoryCollectionViewAdapter: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(CategoryCollectionViewCell.self, for: indexPath)
        cell.configure(with: items[indexPath.item])
        return cell
    }
}

extension CategoryCollectionViewAdapter: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        output?.handleDidSelectCategoryItem(at: indexPath.item)
    }
}
