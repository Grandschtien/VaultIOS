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
        let pages = OnboardingModel.pages
        guard !pages.isEmpty else {
            viewModel = OnboardingViewModel()
            return
        }

        let clampedPage = min(max(.zero, data.currentPage), max(.zero, pages.count - 1))
        let selectedPage = pages[clampedPage]
        let isLastPage = clampedPage == pages.count - 1

        viewModel = OnboardingViewModel(
            pages: pages.map { .init(image: $0.image) },
            title: .init(
                text: selectedPage.title,
                font: Typography.typographySemibold32,
                textColor: Asset.Colors.textAndIconPrimary.color,
                alignment: .center,
                numberOfLines: .zero,
                lineBreakMode: .byWordWrapping
            ),
            subtitle: .init(
                text: selectedPage.subtitle,
                font: Typography.typographyRegular16,
                textColor: Asset.Colors.textAndIconSecondary.color,
                alignment: .center,
                numberOfLines: .zero,
                lineBreakMode: .byWordWrapping
            ),
            pageControl: .init(
                pageCount: pages.count,
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
                isEnabled: !pages.isEmpty,
                tapCommand: Command { [weak handler] in
                    await handler?.didTapPrimaryButton()
                },
                rightIcon: Asset.Icons.arrowRight.image
            ),
            pillViewModel: PillView.ViewModel(
                text: Label.LabelViewModel(
                    text: selectedPage.pillText,
                    font: Typography.typographySemibold12,
                    textColor: Asset.Colors.interactiveElemetsPrimary.color
                ),
                image: selectedPage.pillImage
            ),
            currentPageChangedCommand: CommandOf { [weak handler] page in
                await handler?.didChangeCurrentPage(page)
            },
            scrollCommand: data.scrollCommand.map {
                .init(page: min(max(.zero, $0.page), max(.zero, pages.count - 1)), isAnimated: $0.isAnimated)
            }
        )
    }
}
