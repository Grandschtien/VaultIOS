// Created by Egor Shkarin 11.03.2026

import Foundation

protocol OnboardingBusinessLogic: Sendable {
    func fetchData() async
    func didTapPrimaryButton() async
    func didChangeCurrentPage(_ page: Int) async
}

protocol OnboardingHandler: Sendable, AnyObject {
    func didTapPrimaryButton() async
    func didChangeCurrentPage(_ page: Int) async
}

actor OnboardingInteractor: OnboardingBusinessLogic {
    private let presenter: OnboardingPresentationLogic
    private let router: OnboardingRoutingLogic
    private var currentPage: Int = .zero

    private let pagesCount: Int = OnboardingModel.pages.count

    init(
        presenter: OnboardingPresentationLogic,
        router: OnboardingRoutingLogic
    ) {
        self.presenter = presenter
        self.router = router
    }

    func fetchData() async {
        currentPage = .zero
        await presenter.presentFetchedData(
            OnboardingFetchData(
                currentPage: currentPage,
                scrollCommand: nil
            )
        )
    }
}

// MARK: OnboardingHandler
extension OnboardingInteractor: OnboardingHandler {
    func didTapPrimaryButton() async {
        let lastPage = max(.zero, pagesCount - 1)
        guard currentPage < lastPage else {
            await router.routeToNextScreen()
            return
        }

        currentPage += 1
        await presenter.presentFetchedData(
            OnboardingFetchData(
                currentPage: currentPage,
                scrollCommand: .init(
                    page: currentPage,
                    isAnimated: true
                )
            )
        )
    }

    func didChangeCurrentPage(_ page: Int) async {
        let clampedPage = min(max(.zero, page), max(.zero, pagesCount - 1))
        guard clampedPage != currentPage else {
            return
        }

        currentPage = clampedPage
        await presenter.presentFetchedData(
            OnboardingFetchData(
                currentPage: currentPage,
                scrollCommand: nil
            )
        )
    }
}
