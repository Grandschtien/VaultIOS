// Created by Egor Shkarin 23.03.2026

import Foundation

protocol MainCategoriesProviding: Sendable {
    func fetchCategories() async throws -> [MainCategoryCardModel]
}

final class MainCategoriesProvider: MainCategoriesProviding {
    private enum Constants {
        static let visibleCategoriesLimit = 4
        static let defaultCurrency = "USD"
        static let unmappedBackendName = "Unmapped"
    }

    private let categoriesService: MainCategoriesContractServicing
    private let summaryService: MainSummaryContractServicing
    private let cache: MainDataStoreCache

    init(
        categoriesService: MainCategoriesContractServicing,
        summaryService: MainSummaryContractServicing,
        cache: MainDataStoreCache
    ) {
        self.categoriesService = categoriesService
        self.summaryService = summaryService
        self.cache = cache
    }

    func fetchCategories() async throws -> [MainCategoryCardModel] {
        let categoriesResponse = try await categoriesService.listCategories()
        let visibleCategories = Array(categoriesResponse.categories.prefix(Constants.visibleCategoriesLimit))

        var summariesByCategoryID: [String: SummaryResponseDTO] = [:]
        var categoriesToFetch: [CategoryDTO] = []

        for category in visibleCategories {
            if let cachedSummary = cache.summary(for: category.id) {
                summariesByCategoryID[category.id] = cachedSummary
            } else {
                categoriesToFetch.append(category)
            }
        }

        if !categoriesToFetch.isEmpty {
            await withTaskGroup(of: (String, SummaryResponseDTO?).self) { group in
                for category in categoriesToFetch {
                    group.addTask { [summaryService] in
                        do {
                            let summary = try await summaryService.getSummaryByCategory(
                                id: category.id,
                                parameters: .init()
                            )
                            return (category.id, summary)
                        } catch {
                            return (category.id, nil)
                        }
                    }
                }

                for await (categoryID, summary) in group {
                    guard let summary else {
                        continue
                    }

                    summariesByCategoryID[categoryID] = summary
                    cache.save(summary: summary, for: categoryID)
                }
            }
        }

        return categoriesResponse.categories.map { category in
            let summary = summariesByCategoryID[category.id]

            return MainCategoryCardModel(
                id: category.id,
                name: localizedCategoryName(from: category.name),
                icon: category.icon,
                color: category.color,
                amount: summary?.total ?? .zero,
                currency: summary?.currency ?? Constants.defaultCurrency
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

