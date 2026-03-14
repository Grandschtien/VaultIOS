// Created by Egor Shkarin 11.03.2026

import UIKit

struct OnboardingViewModel: Equatable {
    let selectedPage: Int
    let pageControl: PageControl.PageControlViewModel
    let primaryButton: Button.ButtonViewModel
    let currentPageChangedCommand: CommandOf<Int>?
    let scrollCommand: ScrollCommand?

    init(
        selectedPage: Int = 0,
        pageControl: PageControl.PageControlViewModel = .initial,
        primaryButton: Button.ButtonViewModel = .init(),
        currentPageChangedCommand: CommandOf<Int>? = nil,
        scrollCommand: ScrollCommand? = nil
    ) {
        self.selectedPage = selectedPage
        self.pageControl = pageControl
        self.primaryButton = primaryButton
        self.currentPageChangedCommand = currentPageChangedCommand
        self.scrollCommand = scrollCommand
    }
}

extension OnboardingViewModel {
    struct ScrollCommand: Equatable {
        let page: Int
        let isAnimated: Bool
    }
}
