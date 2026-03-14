// Created by Egor Shkarin 11.03.2026

import Foundation
import UIKit
internal import Combine

@MainActor
protocol OnboardingPresentationLogic: Sendable {
    func presentFetchedData(_ data: OnboardingFetchData)
}

final class OnboardingPresenter: OnboardingPresentationLogic {

    @Published
    private(set) var viewModel: OnboardingViewModel
    
    weak var handler: OnboardingHandler?

    init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
    }

    func presentFetchedData(_ data: OnboardingFetchData) {
        let numberOfPages = 3
        let clampedPage = min(max(.zero, data.currentPage), max(.zero, numberOfPages - 1))
        let isLastPage = clampedPage == numberOfPages - 1

        viewModel = OnboardingViewModel(
            selectedPage: clampedPage,
            pageControl: .init(
                pageCount: numberOfPages,
                currentPage: clampedPage,
                activeColor: Asset.Colors.interactiveElemetsPrimary.color,
                inactiveColor: Asset.Colors.textAndIconPlaceseholder.color,
                indicatorSize: 8,
                activeWidth: 24,
                spacing: 8,
                allowsSelection: true
            ),
            primaryButton: .init(
                title: isLastPage ? L10n.getStarted : L10n.next,
                titleColor: Asset.Colors.textAndIconPrimaryInverted.color,
                backgroundColor: Asset.Colors.interactiveElemetsPrimary.color,
                font: Typography.typographySemibold16,
                isEnabled: true,
                tapCommand: Command { [weak handler] in
                    await handler?.didTapPrimaryButton()
                },
                rightIcon: Asset.Icons.arrowRight.image
            ),
            currentPageChangedCommand: CommandOf { [weak handler] page in
                await handler?.didChangeCurrentPage(page)
            },
            scrollCommand: data.scrollCommand.map {
                .init(page: min(max(.zero, $0.page), max(.zero, numberOfPages - 1)), isAnimated: $0.isAnimated)
            }
        )
    }
}
