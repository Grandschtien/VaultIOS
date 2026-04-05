import Nivelir

@MainActor
struct AddExpenseScreens {
    let context: MainFlowContext

    func entryChooserScreen() -> AnyModalScreen {
        ExpenseEntryChooserFactory(context: context).eraseToAnyScreen()
    }

    func aiEntryScreen() -> AnyModalScreen {
        ExpenseAIEntryFactory(context: context).eraseToAnyScreen()
    }

    func manualEntryScreen(
        initialDrafts: [ExpenseEditableDraft] = []
    ) -> AnyModalScreen {
        ExpenseManualEntryFactory(
            context: context,
            initialDrafts: initialDrafts
        )
        .eraseToAnyScreen()
    }

    func categoryPickerScreen(
        selectedCategoryID: String?,
        output: ExpenseCategoryPickerOutput
    ) -> AnyModalScreen {
        ExpenseCategoryPickerFactory(
            selectedCategoryID: selectedCategoryID,
            output: output,
            context: context
        )
        .eraseToAnyScreen()
    }
}
