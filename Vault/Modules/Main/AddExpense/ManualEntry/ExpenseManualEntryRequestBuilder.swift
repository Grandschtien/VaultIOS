import Foundation

struct ExpenseManualEntryRequestBuilder: Sendable {
    func isValidDraft(_ draft: ExpenseEditableDraft) -> Bool {
        guard draft.selectedCategory != nil else {
            return false
        }

        guard !normalizedTitle(from: draft.titleText).isEmpty else {
            return false
        }

        guard let amount = normalizedAmount(from: draft.amountText) else {
            return false
        }

        return amount > .zero
    }

    func makeRequest(
        drafts: [ExpenseEditableDraft],
        timeOfAdd: Date
    ) -> ExpensesCreateRequestDTO? {
        let expenses = drafts.compactMap { draft -> ExpenseCreateItemRequestDTO? in
            guard let selectedCategory = draft.selectedCategory,
                  let amount = normalizedAmount(from: draft.amountText) else {
                return nil
            }

            let title = normalizedTitle(from: draft.titleText)
            guard !title.isEmpty else {
                return nil
            }

            let currency = draft.currencyCode
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .uppercased()
            guard !currency.isEmpty else {
                return nil
            }

            return ExpenseCreateItemRequestDTO(
                title: title,
                description: draft.descriptionText.trimmingCharacters(in: .whitespacesAndNewlines),
                amount: amount,
                currency: currency,
                category: selectedCategory.id,
                timeOfAdd: timeOfAdd
            )
        }

        guard expenses.count == drafts.count,
              !expenses.isEmpty else {
            return nil
        }

        return ExpensesCreateRequestDTO(expenses: expenses)
    }
}

private extension ExpenseManualEntryRequestBuilder {
    func normalizedTitle(from text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func normalizedAmount(from text: String) -> Double? {
        let trimmedText = text.filter { !$0.isWhitespace }
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
