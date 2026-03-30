// Created by Codex on 30.03.2026

import UIKit

extension UITableView {
    func register<Cell: UITableViewCell & Reusable>(_ cellType: Cell.Type) {
        register(cellType, forCellReuseIdentifier: cellType.reuseId)
    }

    func dequeueReusableCell<Cell: UITableViewCell & Reusable>(
        _ cellType: Cell.Type,
        for indexPath: IndexPath
    ) -> Cell {
        guard let cell = dequeueReusableCell(withIdentifier: cellType.reuseId, for: indexPath) as? Cell else {
            fatalError("Failed to dequeue \(cellType.reuseId)")
        }

        return cell
    }

    func dequeueReusableCell<Cell: UITableViewCell & Reusable>(_ cellType: Cell.Type) -> Cell? {
        dequeueReusableCell(withIdentifier: cellType.reuseId) as? Cell
    }
}

extension UICollectionView {
    func register<Cell: UICollectionViewCell & Reusable>(_ cellType: Cell.Type) {
        register(cellType, forCellWithReuseIdentifier: cellType.reuseId)
    }

    func dequeueReusableCell<Cell: UICollectionViewCell & Reusable>(
        _ cellType: Cell.Type,
        for indexPath: IndexPath
    ) -> Cell {
        guard let cell = dequeueReusableCell(
            withReuseIdentifier: cellType.reuseId,
            for: indexPath
        ) as? Cell else {
            fatalError("Failed to dequeue \(cellType.reuseId)")
        }

        return cell
    }
}
