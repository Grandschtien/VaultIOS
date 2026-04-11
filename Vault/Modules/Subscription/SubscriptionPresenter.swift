// Created by Egor Shkarin 08.04.2026

import Foundation
import UIKit
internal import Combine

@MainActor
protocol SubscriptionPresentationLogic: Sendable {
    func presentFetchedData(_ data: SubscriptionFetchData)
}

final class SubscriptionPresenter: SubscriptionPresentationLogic {
    @Published
    private(set) var viewModel: SubscriptionViewModel

    weak var handler: SubscriptionHandler?

    init(viewModel: SubscriptionViewModel) {
        self.viewModel = viewModel
    }

    func presentFetchedData(_ data: SubscriptionFetchData) {
        viewModel = SubscriptionViewModel(
            header: .init(
                title: .init(
                    text: data.title,
                    font: Typography.typographyBold20,
                    textColor: Asset.Colors.textAndIconPrimary.color,
                    alignment: .center
                ),
                isCloseEnabled: data.purchasingPlanID == nil,
                closeCommand: Command { [weak handler] in
                    await handler?.handleTapClose()
                }
            ),
            state: makeState(from: data)
        )
    }
}

private extension SubscriptionPresenter {
    func makeState(from data: SubscriptionFetchData) -> SubscriptionViewModel.State {
        switch data.loadingState {
        case .idle, .loading:
            return .loading
        case .failed:
            return .error(makeErrorViewModel())
        case .loaded:
            return .loaded(makeContent(from: data))
        }
    }

    func makeContent(from data: SubscriptionFetchData) -> SubscriptionViewModel.Content {
        let currentPlan = SubscriptionPlanResolver.currentPlan(from: data.currentTier)
        let currentProductID = SubscriptionPlanResolver.currentProductID(from: data.currentTier)
        let availablePlans = data.plans.filter { $0.id != currentProductID }

        return SubscriptionViewModel.Content(
            title: .init(
                text: L10n.subscriptionSubtitle,
                font: Typography.typographyBold24,
                textColor: Asset.Colors.textAndIconPrimary.color,
                alignment: .left,
                numberOfLines: 0
            ),
            subtitle: .init(
                text: L10n.subscriptionDescription,
                font: Typography.typographyRegular14,
                textColor: Asset.Colors.textAndIconPlaceseholder.color,
                alignment: .left,
                numberOfLines: 0
            ),
            currentPlan: .init(
                title: .init(
                    text: L10n.subscriptionCurrentPlan,
                    font: Typography.typographySemibold14,
                    textColor: Asset.Colors.textAndIconPlaceseholder.color,
                    alignment: .left
                ),
                planTitle: .init(
                    text: currentPlan.title,
                    font: Typography.typographyBold20,
                    textColor: Asset.Colors.textAndIconPrimary.color,
                    alignment: .left
                ),
                description: .init(
                    text: currentPlan.description,
                    font: Typography.typographyRegular14,
                    textColor: Asset.Colors.textAndIconPlaceseholder.color,
                    alignment: .left,
                    numberOfLines: 0
                )
            ),
            plans: availablePlans.map { plan in
                makePlanCard(
                    plan: plan,
                    purchasingPlanID: data.purchasingPlanID
                )
            }
        )
    }

    func makePlanCard(
        plan: SubscriptionStorePlan,
        purchasingPlanID: String?
    ) -> SubscriptionViewModel.PlanCard {
        let isPurchasing = purchasingPlanID == plan.id
        let isAnotherPlanPurchasing = purchasingPlanID != nil && !isPurchasing

        return SubscriptionViewModel.PlanCard(
            id: plan.id,
            title: .init(
                text: plan.title,
                font: Typography.typographyBold20,
                textColor: Asset.Colors.textAndIconPrimary.color,
                alignment: .left
            ),
            description: .init(
                text: SubscriptionPlanResolver.description(for: plan.id),
                font: Typography.typographyRegular14,
                textColor: Asset.Colors.textAndIconPlaceseholder.color,
                alignment: .left,
                numberOfLines: 0
            ),
            price: .init(
                text: L10n.subscriptionPerMonth(plan.price),
                font: Typography.typographyBold28,
                textColor: Asset.Colors.interactiveElemetsPrimary.color,
                alignment: .left
            ),
            button: .init(
                title: L10n.subscriptionBuy,
                titleColor: Asset.Colors.textAndIconPrimaryInverted.color,
                backgroundColor: Asset.Colors.interactiveElemetsPrimary.color,
                font: Typography.typographySemibold16,
                isEnabled: !isAnotherPlanPurchasing,
                isLoading: isPurchasing,
                tapCommand: Command { [weak handler] in
                    await handler?.handleTapPurchase(planID: plan.id)
                }
            )
        )
    }

    func makeErrorViewModel() -> FullScreenCommonErrorView.ViewModel {
        FullScreenCommonErrorView.ViewModel(
            title: .init(
                text: L10n.subscriptionLoadingFailed,
                font: Typography.typographyBold14,
                textColor: Asset.Colors.textAndIconSecondary.color,
                alignment: .center
            ),
            tapCommand: Command { [weak handler] in
                await handler?.handleTapRetry()
            }
        )
    }
}
