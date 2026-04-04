import Nivelir

@MainActor
struct AddExpenseScreens {
    let context: MainFlowContext

    func entryChooserScreen() -> AnyModalScreen {
        ExpenseEntryChooserFactory(context: context).eraseToAnyScreen()
    }

    func aiEntryScreen() -> AnyModalScreen {
        ExpenseAIEntryFactory().eraseToAnyScreen()
    }

    func manualEntryScreen() -> AnyModalScreen {
        ExpenseManualEntryFactory(context: context).eraseToAnyScreen()
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
