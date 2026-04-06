// Created by Egor Shkarin on 28.03.2026

import UIKit

struct CategoryViewModel: Equatable {
    let navigationTitle: Label.LabelViewModel
    let content: ContentViewModel
    let loadNextPageCommand: Command

    init(
        navigationTitle: Label.LabelViewModel = .init(),
        content: ContentViewModel = .init(),
        loadNextPageCommand: Command = .nope
    ) {
        self.navigationTitle = navigationTitle
        self.content = content
        self.loadNextPageCommand = loadNextPageCommand
    }
}

extension CategoryViewModel {
    struct ContentViewModel: Equatable {
        enum State: Equatable {
            case failed(FullScreenCommonErrorView.ViewModel)
            case loading([SectionViewModel])
            case loaded([SectionViewModel])
            case empty(String)
        }

        let summary: SummaryViewModel
        let state: State
        let isLoadingNextPage: Bool
        let hasMore: Bool

        init(
            summary: SummaryViewModel = .init(isLoading: true),
            state: State = .loading([]),
            isLoadingNextPage: Bool = false,
            hasMore: Bool = false
        ) {
            self.summary = summary
            self.state = state
            self.isLoadingNextPage = isLoadingNextPage
            self.hasMore = hasMore
        }
    }

    struct SummaryViewModel: Equatable {
        let iconText: String
        let cardBackgroundColor: UIColor
        let cardBorderColor: UIColor
        let iconBackgroundColor: UIColor
        let title: Label.LabelViewModel
        let amount: Label.LabelViewModel
        let note: Label.LabelViewModel
        let isLoading: Bool

        init(
            iconText: String = "",
            cardBackgroundColor: UIColor = Asset.Colors.interactiveInputBackground.color,
            cardBorderColor: UIColor = Asset.Colors.interactiveInputBackground.color,
            iconBackgroundColor: UIColor = Asset.Colors.interactiveInputBackground.color,
            title: Label.LabelViewModel = .init(),
            amount: Label.LabelViewModel = .init(),
            note: Label.LabelViewModel = .init(),
            isLoading: Bool = false
        ) {
            self.iconText = iconText
            self.cardBackgroundColor = cardBackgroundColor
            self.cardBorderColor = cardBorderColor
            self.iconBackgroundColor = iconBackgroundColor
            self.title = title
            self.amount = amount
            self.note = note
            self.isLoading = isLoading
        }
    }

    struct SectionViewModel: Equatable {
        let id: String
        let title: Label.LabelViewModel
        let items: [ExpenseItemViewModel]

        init(
            id: String = "",
            title: Label.LabelViewModel = .init(),
            items: [ExpenseItemViewModel] = []
        ) {
            self.id = id
            self.title = title
            self.items = items
        }
    }

    struct ExpenseItemViewModel: Equatable {
        enum DeleteState: Equatable {
            case idle
            case deleting
        }

        let id: String
        let iconText: String
        let iconBackgroundColor: UIColor
        let title: Label.LabelViewModel
        let subtitle: Label.LabelViewModel
        let amount: Label.LabelViewModel
        let isLoading: Bool
        let deleteLabel: Label.LabelViewModel
        let deleteState: DeleteState
        let deleteCommand: Command

        init(
            id: String = "",
            iconText: String = "",
            iconBackgroundColor: UIColor = Asset.Colors.interactiveInputBackground.color,
            title: Label.LabelViewModel = .init(),
            subtitle: Label.LabelViewModel = .init(),
            amount: Label.LabelViewModel = .init(),
            isLoading: Bool = false,
            deleteLabel: Label.LabelViewModel = .init(),
            deleteState: DeleteState = .idle,
            deleteCommand: Command = .nope
        ) {
            self.id = id
            self.iconText = iconText
            self.iconBackgroundColor = iconBackgroundColor
            self.title = title
            self.subtitle = subtitle
            self.amount = amount
            self.isLoading = isLoading
            self.deleteLabel = deleteLabel
            self.deleteState = deleteState
            self.deleteCommand = deleteCommand
        }
    }
}
