// Created by Egor Shkarin 11.03.2026

import UIKit

struct OnboardingViewModel: Equatable {
    let pages: [PageViewModel]
    let title: Label.LabelViewModel
    let subtitle: Label.LabelViewModel
    let pageControl: PageControl.PageControlViewModel
    let primaryButton: Button.ButtonViewModel
    let pillViewModel: PillView.ViewModel
    let currentPageChangedCommand: CommandOf<Int>?
    let scrollCommand: ScrollCommand?

    init(
        pages: [PageViewModel] = [],
        title: Label.LabelViewModel = .init(),
        subtitle: Label.LabelViewModel = .init(),
        pageControl: PageControl.PageControlViewModel = .initial,
        primaryButton: Button.ButtonViewModel = .init(),
        pillViewModel: PillView.ViewModel = .init(),
        currentPageChangedCommand: CommandOf<Int>? = nil,
        scrollCommand: ScrollCommand? = nil
    ) {
        self.pages = pages
        self.title = title
        self.subtitle = subtitle
        self.pageControl = pageControl
        self.primaryButton = primaryButton
        self.pillViewModel = pillViewModel
        self.currentPageChangedCommand = currentPageChangedCommand
        self.scrollCommand = scrollCommand
    }
}

extension OnboardingViewModel {
    struct PageViewModel: Equatable {
        let image: Image
    }

    struct ScrollCommand: Equatable {
        let page: Int
        let isAnimated: Bool
    }

    enum Image: String, Equatable {
        case onboarding1 = "onboarding_1"
        case onboarding2 = "onboarding_2"
        case onboarding3 = "onboarding_3"
    }
}
