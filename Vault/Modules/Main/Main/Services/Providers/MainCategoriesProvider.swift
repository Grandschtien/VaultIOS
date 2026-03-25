// Created by Egor Shkarin 23.03.2026

import Foundation

protocol MainCategoriesProviding: Sendable {
    func fetchCategories() async throws -> [MainCategoryCardModel]
}

final class MainCategoriesProvider: MainCategoriesProviding {
    private enum Constants {
        static let defaultCurrency = "USD"
        static let unmappedBackendName = "Unmapped"
    }

    private let categoriesService: MainCategoriesContractServicing

    init(
        categoriesService: MainCategoriesContractServicing
    ) {
        self.categoriesService = categoriesService
    }

    func fetchCategories() async throws -> [MainCategoryCardModel] {
        let categoriesResponse = try await categoriesService.listCategories()

        return categoriesResponse.categories.map { category in
            return MainCategoryCardModel(
                id: category.id,
                name: localizedCategoryName(from: category.name),
                icon: category.icon,
                color: category.color,
                amount: category.totalSpentUsd,
                currency: Constants.defaultCurrency
            )
        }
    }

    private func localizedCategoryName(from backendName: String) -> String {
        if backendName.compare(Constants.unmappedBackendName, options: [.caseInsensitive]) == .orderedSame {
            return L10n.other
        }

        return backendName
    }
}
