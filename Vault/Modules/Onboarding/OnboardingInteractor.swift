// Created by Egor Shkarin 11.03.2026

import Foundation

protocol OnboardingBusinessLogic {
    func fetchData() async
    func didTapPrimaryButton() async
    func didChangeCurrentPage(_ page: Int) async
}

protocol OnboardingHandler: AnyObject {
    func didTapPrimaryButton() async
    func didChangeCurrentPage(_ page: Int) async
}

protocol OnboardingFlowOutput: AnyObject {
    func didFinishOnboarding() async
}

final class OnboardingInteractor: OnboardingBusinessLogic {
    private let presenter: OnboardingPresentationLogic
    private var currentPage: Int = .zero
    
    weak var output: OnboardingFlowOutput?

    private let pagesCount: Int = OnboardingModel.pages.count

    init(
        presenter: OnboardingPresentationLogic
    ) {
        self.presenter = presenter
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
            await output?.didFinishOnboarding()
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
