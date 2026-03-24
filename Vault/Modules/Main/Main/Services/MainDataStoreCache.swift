// Created by Codex on 24.03.2026

import Foundation

final class MainDataStoreCache: @unchecked Sendable {
    private let lock = NSLock()
    private var categorySummaries: [String: SummaryResponseDTO] = [:]

    func summary(for categoryID: String) -> SummaryResponseDTO? {
        lock.withLock {
            categorySummaries[categoryID]
        }
    }

    func save(summary: SummaryResponseDTO, for categoryID: String) {
        lock.withLock {
            categorySummaries[categoryID] = summary
        }
    }

    func clear() {
        lock.withLock {
            categorySummaries = [:]
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
