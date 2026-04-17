import Foundation

struct ExpenseAIParsedDraftMapper: Sendable {
    private enum Constants {
        static let unmappedCategory = "UNMAPPED"
    }

    func makeDrafts(
        from expenses: [AIParsedExpenseDTO],
        categories: [MainCategoryCardModel],
        fallbackCurrencyCode: String
    ) -> [ExpenseEditableDraft] {
        expenses.map {
            ExpenseEditableDraft(
                amountText: normalizedAmountText(for: $0.amount),
                titleText: $0.title.trimmingCharacters(in: .whitespacesAndNewlines),
                descriptionText: "",
                selectedCategory: resolveCategory(
                    categoryName: $0.category,
                    suggestedCategoryName: $0.suggestedCategory,
                    categories: categories
                ),
                currencyCode: normalizedCurrencyCode(
                    parsedCurrency: $0.currency,
                    fallbackCurrencyCode: fallbackCurrencyCode
                )
            )
        }
    }
}

private extension ExpenseAIParsedDraftMapper {
    func normalizedAmountText(for amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2

        return formatter.string(from: NSNumber(value: amount))
            ?? String(amount)
    }

    func normalizedCurrencyCode(
        parsedCurrency: String,
        fallbackCurrencyCode: String
    ) -> String {
        let normalized = parsedCurrency.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if normalized.isEmpty {
            return fallbackCurrencyCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        }

        return normalized
    }

    func resolveCategory(
        categoryName: String,
        suggestedCategoryName: String?,
        categories: [MainCategoryCardModel]
    ) -> ExpenseCategorySelectionModel? {
        if let selectedCategory = matchCategory(named: categoryName, in: categories) {
            return selectedCategory
        }

        guard categoryName.compare(Constants.unmappedCategory, options: [.caseInsensitive]) == .orderedSame,
              let suggestedCategoryName,
              let selectedCategory = matchCategory(named: suggestedCategoryName, in: categories) else {
            return nil
        }

        return selectedCategory
    }

    func matchCategory(
        named name: String,
        in categories: [MainCategoryCardModel]
    ) -> ExpenseCategorySelectionModel? {
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedName.isEmpty else {
            return nil
        }

        guard let category = categories.first(where: {
            $0.name.compare(normalizedName, options: [.caseInsensitive]) == .orderedSame
        }) else {
            return nil
        }

        return ExpenseCategorySelectionModel(
            id: category.id,
            name: category.name,
            icon: category.icon,
            color: category.color
        )
    }
}
