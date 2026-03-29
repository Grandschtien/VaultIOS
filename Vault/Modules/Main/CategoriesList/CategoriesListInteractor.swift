// Created by Egor Shkarin on 27.03.2026

import Foundation

protocol CategoriesListBusinessLogic: Sendable {
    func fetchData() async
}

protocol CategoriesListHandler: AnyObject, Sendable {
    func handleTapRetry() async
    func handleTapCategory(id: String, name: String) async
}

actor CategoriesListInteractor: CategoriesListBusinessLogic {
    private let presenter: CategoriesListPresentationLogic
    private let router: CategoriesListRoutingLogic
    private let categoriesProvider: CategoriesListCategoriesProviding

    private var loadingState: LoadingStatus = .idle
    private var categories: [MainCategoryCardModel] = []

    init(
        presenter: CategoriesListPresentationLogic,
        router: CategoriesListRoutingLogic,
        categoriesProvider: CategoriesListCategoriesProviding
    ) {
        self.presenter = presenter
        self.router = router
        self.categoriesProvider = categoriesProvider
    }

    func fetchData() async {
        loadingState = .loading
        categories = []
        await presentFetchedData()

        if let cachedCategories = categoriesProvider.cachedCategories(), !cachedCategories.isEmpty {
            categories = cachedCategories
            loadingState = .loaded
            await presentFetchedData()
        }

        do {
            categories = try await categoriesProvider.fetchCategories()
            loadingState = .loaded
            await presentFetchedData()
        } catch {
            if categories.isEmpty {
                loadingState = .failed(.undelinedError(description: error.localizedDescription))
                await presentFetchedData()
            }
        }
    }
}

private extension CategoriesListInteractor {
    func presentFetchedData() async {
        await presenter.presentFetchedData(
            CategoriesListFetchData(
                loadingState: loadingState,
                categories: categories
            )
        )
    }
}

extension CategoriesListInteractor: CategoriesListHandler {
    func handleTapRetry() async {
        await fetchData()
    }

    func handleTapCategory(id: String, name: String) async {
        await router.openCategory(id: id, name: name)
    }
}
