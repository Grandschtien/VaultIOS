// Created by Egor Shkarin 08.04.2026

import Foundation

struct SubscriptionViewModel: Equatable {
    let header: AddExpenseSheetHeaderView.ViewModel
    let state: State

    init(
        header: AddExpenseSheetHeaderView.ViewModel = .init(),
        state: State = .loading
    ) {
        self.header = header
        self.state = state
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

        init(
            title: Label.LabelViewModel = .init(),
            subtitle: Label.LabelViewModel = .init(),
            currentPlan: CurrentPlanCard = .init(),
            plans: [PlanCard] = []
        ) {
            self.title = title
            self.subtitle = subtitle
            self.currentPlan = currentPlan
            self.plans = plans
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
