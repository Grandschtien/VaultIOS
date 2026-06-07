// Created by Egor Shkarin 08.04.2026

import Foundation

struct SubscriptionViewModel: Equatable {
    let header: AddExpenseSheetHeaderView.ViewModel
    let state: State
    let isDismissLocked: Bool
    let isOverlayLoading: Bool
    let overlayMessage: Label.LabelViewModel?

    init(
        header: AddExpenseSheetHeaderView.ViewModel = .init(),
        state: State = .loading,
        isDismissLocked: Bool = false,
        isOverlayLoading: Bool = false,
        overlayMessage: Label.LabelViewModel? = nil
    ) {
        self.header = header
        self.state = state
        self.isDismissLocked = isDismissLocked
        self.isOverlayLoading = isOverlayLoading
        self.overlayMessage = overlayMessage
    }
}

extension SubscriptionViewModel {
    enum State: Equatable {
        case loading
        case loaded(Content)
        case error(FullScreenCommonErrorView.ViewModel)
    }
}

extension SubscriptionViewModel {
    struct Content: Equatable {
        let title: Label.LabelViewModel
        let subtitle: Label.LabelViewModel
        let currentPlan: CurrentPlanCard
        let plans: [PlanCard]
        let restoreButton: Button.ButtonViewModel

        init(
            title: Label.LabelViewModel = .init(),
            subtitle: Label.LabelViewModel = .init(),
            currentPlan: CurrentPlanCard = .init(),
            plans: [PlanCard] = [],
            restoreButton: Button.ButtonViewModel = .init()
        ) {
            self.title = title
            self.subtitle = subtitle
            self.currentPlan = currentPlan
            self.plans = plans
            self.restoreButton = restoreButton
        }
    }

    struct CurrentPlanCard: Equatable {
        let title: Label.LabelViewModel
        let planTitle: Label.LabelViewModel
        let description: Label.LabelViewModel

        init(
            title: Label.LabelViewModel = .init(),
            planTitle: Label.LabelViewModel = .init(),
            description: Label.LabelViewModel = .init()
        ) {
            self.title = title
            self.planTitle = planTitle
            self.description = description
        }
    }

    struct PlanCard: Equatable {
        let id: String
        let title: Label.LabelViewModel
        let description: Label.LabelViewModel
        let price: Label.LabelViewModel
        let button: Button.ButtonViewModel

        init(
            id: String = "",
            title: Label.LabelViewModel = .init(),
            description: Label.LabelViewModel = .init(),
            price: Label.LabelViewModel = .init(),
            button: Button.ButtonViewModel = .init()
        ) {
            self.id = id
            self.title = title
            self.description = description
            self.price = price
            self.button = button
        }
    }
}
