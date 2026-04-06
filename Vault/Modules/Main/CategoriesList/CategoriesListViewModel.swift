// Created by Egor Shkarin on 27.03.2026

import Foundation

struct CategoriesListViewModel: Equatable {
    let navigationTitle: Label.LabelViewModel
    let addButton: NavigationBarActionView.ViewModel
    let state: State

    init(
        navigationTitle: Label.LabelViewModel = .init(),
        addButton: NavigationBarActionView.ViewModel = .init(),
        state: State = .loading(items: [])
    ) {
        self.navigationTitle = navigationTitle
        self.addButton = addButton
        self.state = state
    }
}

extension CategoriesListViewModel {
    enum State: Equatable {
        case error(FullScreenCommonErrorView.ViewModel)
        case loading(items: [CategoryCollectionViewCell.ViewModel])
        case empty(text: String)
        case loaded(items: [CategoryCollectionViewCell.ViewModel])
    }
}
