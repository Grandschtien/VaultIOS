// Created by Egor Shkarin on 27.03.2026

import Foundation

protocol CategoriesListCategoriesProviding: Sendable {
    func cachedCategories() -> [MainCategoryCardModel]?
    func fetchCategories() async throws -> [MainCategoryCardModel]
}

final class CategoriesListCategoriesProvider: CategoriesListCategoriesProviding {
    private enum Constants {
        static let unmappedBackendName = "Unmapped"
    }

    private let categoriesService: MainCategoriesContractServicing
    private let cache: MainDataStoreCache

    init(
        categoriesService: MainCategoriesContractServicing,
        cache: MainDataStoreCache
    ) {
        self.categoriesService = categoriesService
        self.cache = cache
    }

    func cachedCategories() -> [MainCategoryCardModel]? {
        cache.categories()
    }

    func fetchCategories() async throws -> [MainCategoryCardModel] {
        let categoriesResponse = try await categoriesService.listCategories()
        let categories = categoriesResponse.categories.map { category in
            return MainCategoryCardModel(
                id: category.id,
                name: localizedCategoryName(from: category.name),
                icon: category.icon,
                color: category.color,
                amount: category.displayedAmount,
                currency: category.displayedCurrency
            )
        }

        cache.save(categories: categories)
        return categories
    }
}

private extension CategoriesListCategoriesProvider {
    func localizedCategoryName(from backendName: String) -> String {
        if backendName.compare(Constants.unmappedBackendName, options: [.caseInsensitive]) == .orderedSame {
            return L10n.other
        }

        return backendName
    }
}
