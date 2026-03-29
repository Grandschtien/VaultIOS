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
    private let currencyConversionService: UserCurrencyConverting

    init(
        categoriesService: MainCategoriesContractServicing,
        cache: MainDataStoreCache,
        currencyConversionService: UserCurrencyConverting
    ) {
        self.categoriesService = categoriesService
        self.cache = cache
        self.currencyConversionService = currencyConversionService
    }

    func cachedCategories() -> [MainCategoryCardModel]? {
        cache.categories()
    }

    func fetchCategories() async throws -> [MainCategoryCardModel] {
        let categoriesResponse = try await categoriesService.listCategories()
        let categories = categoriesResponse.categories.map { category in
            let convertedAmount = currencyConversionService.convertUsdAmount(category.totalSpentUsd ?? .zero)
            return MainCategoryCardModel(
                id: category.id,
                name: localizedCategoryName(from: category.name),
                icon: category.icon,
                color: category.color,
                amount: convertedAmount.amount,
                currency: convertedAmount.currency
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
