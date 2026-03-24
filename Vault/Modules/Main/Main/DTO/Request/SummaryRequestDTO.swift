// Created by Codex on 24.03.2026

import Foundation

struct SummaryQueryParameters: Equatable, Sendable {
    let from: Date?
    let to: Date?

    init(from: Date? = nil, to: Date? = nil) {
        self.from = from
        self.to = to
    }
}
