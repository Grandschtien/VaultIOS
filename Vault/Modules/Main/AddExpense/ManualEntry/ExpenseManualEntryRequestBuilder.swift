import Foundation

struct ExpenseManualEntryRequestBuilder: Sendable {
    func isValidDraft(
        amountText: String,
        titleText: String,
        selectedCategory: ExpenseCategorySelectionModel?
    ) -> Bool {
        guard selectedCategory != nil else {
            return false
        }

        guard !normalizedTitle(from: titleText).isEmpty else {
            return false
        }

        guard let amount = normalizedAmount(from: amountText) else {
            return false
        }

        return amount > .zero
    }

    func makeRequest(
        amountText: String,
        titleText: String,
        descriptionText: String,
        selectedCategory: ExpenseCategorySelectionModel?,
        currencyCode: String,
        timeOfAdd: Date
    ) -> ExpensesCreateRequestDTO? {
        guard let selectedCategory,
              let amount = normalizedAmount(from: amountText) else {
            return nil
        }

        let title = normalizedTitle(from: titleText)
        guard !title.isEmpty else {
            return nil
        }

        let currency = currencyCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !currency.isEmpty else {
            return nil
        }

        return ExpensesCreateRequestDTO(
            expenses: [
                ExpenseCreateItemRequestDTO(
                    title: title,
                    description: descriptionText.trimmingCharacters(in: .whitespacesAndNewlines),
                    amount: amount,
                    currency: currency,
                    category: selectedCategory.id,
                    timeOfAdd: timeOfAdd
                )
            ]
        )
    }
}

private extension ExpenseManualEntryRequestBuilder {
    func normalizedTitle(from text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func normalizedAmount(from text: String) -> Double? {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            return nil
        }

        if let amount = Double(trimmedText), amount > .zero {
            return amount
        }

        let normalizedText = trimmedText.replacingOccurrences(of: ",", with: ".")
        guard normalizedText != trimmedText,
              let amount = Double(normalizedText),
              amount > .zero else {
            return nil
        }

        return amount
    }
}
