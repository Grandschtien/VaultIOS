// Created by Egor Shkarin 11.03.2026

import Foundation

struct OnboardingFetchData: Sendable {
    let currentPage: Int
    let scrollCommand: ScrollCommand?
}

extension OnboardingFetchData {
    struct ScrollCommand: Sendable {
        let page: Int
        let isAnimated: Bool
    }
}
