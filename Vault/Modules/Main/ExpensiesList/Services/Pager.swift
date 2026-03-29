// Created by Egor Shkarin on 25.03.2026

import Foundation

struct PagerRequest: Equatable, Sendable {
    let cursor: String?
}

protocol PagerLogic: Sendable {
    func reset()
    func beginNextPageIfPossible() -> PagerRequest?
    func commitPage(nextCursor: String?, hasMore: Bool)
    func rollbackAfterError()
    func hasMorePages() -> Bool
    func isLoadingPage() -> Bool
}

final class Pager: PagerLogic {
    private var cursor: String?
    private var hasMore: Bool = true
    private var isLoading: Bool = false

    func reset() {
        cursor = nil
        hasMore = true
        isLoading = false
    }

    func beginNextPageIfPossible() -> PagerRequest? {
        guard hasMore, !isLoading else {
            return nil
        }

        isLoading = true
        return PagerRequest(cursor: cursor)
    }

    func commitPage(nextCursor: String?, hasMore: Bool) {
        cursor = nextCursor
        self.hasMore = hasMore
        isLoading = false
    }

    func rollbackAfterError() {
        isLoading = false
    }

    func hasMorePages() -> Bool {
        hasMore
    }

    func isLoadingPage() -> Bool {
        isLoading
    }
}
