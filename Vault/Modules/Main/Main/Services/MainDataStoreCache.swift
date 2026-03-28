// Created by Codex on 27.03.2026

import Foundation

final class MainDataStoreCache: @unchecked Sendable {
    private let lock = NSLock()
    private var cachedCategories: [MainCategoryCardModel]?

    func categories() -> [MainCategoryCardModel]? {
        lock.withLock {
            cachedCategories
        }
    }

    func save(categories: [MainCategoryCardModel]) {
        lock.withLock {
            cachedCategories = categories
        }
    }

    func clear() {
        lock.withLock {
            cachedCategories = nil
        }
    }
}

private extension NSLock {
    func withLock<T>(_ block: () -> T) -> T {
        lock()
        defer { unlock() }
        return block()
    }
}
