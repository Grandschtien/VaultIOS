// Created by Egor Shkarin 25.03.2026

import Foundation
import UIKit

struct ExpesiesListViewModel: Equatable {
    let navigationTitle: Label.LabelViewModel
    let state: State
    let loadNextPageCommand: Command

    init(
        navigationTitle: Label.LabelViewModel = .init(),
        state: State = .loading(sections: []),
        loadNextPageCommand: Command = .nope
    ) {
        self.navigationTitle = navigationTitle
        self.state = state
        self.loadNextPageCommand = loadNextPageCommand
    }
}

extension ExpesiesListViewModel {
    enum State: Equatable {
        case error(FullScreenCommonErrorView.ViewModel)
        case loading(sections: [SectionViewModel])
        case empty(text: String)
        case loaded(LoadedContent)
    }

    struct LoadedContent: Equatable {
        let sections: [SectionViewModel]
        let isLoadingNextPage: Bool
        let hasMore: Bool

        init(
            sections: [SectionViewModel] = [],
            isLoadingNextPage: Bool = false,
            hasMore: Bool = false
        ) {
            self.sections = sections
            self.isLoadingNextPage = isLoadingNextPage
            self.hasMore = hasMore
        }
    }

    struct SectionViewModel: Equatable {
        let title: Label.LabelViewModel
        let items: [ExpenseView.ViewModel]

        init(
            title: Label.LabelViewModel = .init(),
            items: [ExpenseView.ViewModel] = []
        ) {
            self.title = title
            self.items = items
        }
    }
}
