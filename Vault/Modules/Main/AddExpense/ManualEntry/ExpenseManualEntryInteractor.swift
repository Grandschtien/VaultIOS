import Foundation

protocol ExpenseManualEntryBusinessLogic: Sendable {
    func fetchData() async
}

protocol ExpenseManualEntryHandler: AnyObject, Sendable {
    func handleChangeAmount(_ text: String) async
    func handleChangeTitle(_ text: String) async
    func handleChangeDescription(_ text: String) async
    func handleTapCategory() async
    func handleTapConfirm() async
    func handleTapClose() async
}

actor ExpenseManualEntryInteractor: ExpenseManualEntryBusinessLogic {
    private let presenter: ExpenseManualEntryPresentationLogic
    private let router: ExpenseManualEntryRoutingLogic

    private var amountText: String = ""
    private var titleText: String = ""
    private var descriptionText: String = ""
    private var selectedCategory: ExpenseCategorySelectionModel?

    init(
        presenter: ExpenseManualEntryPresentationLogic,
        router: ExpenseManualEntryRoutingLogic
    ) {
        self.presenter = presenter
        self.router = router
    }

    func fetchData() async {
        await presentFetchedData()
    }
}

private extension ExpenseManualEntryInteractor {
    func presentFetchedData() async {
        await presenter.presentFetchedData(
            ExpenseManualEntryFetchData(
                amountText: amountText,
                titleText: titleText,
                descriptionText: descriptionText,
                selectedCategory: selectedCategory
            )
        )
    }
}

extension ExpenseManualEntryInteractor: ExpenseManualEntryHandler {
    func handleChangeAmount(_ text: String) async {
        amountText = text
        await presentFetchedData()
    }

    func handleChangeTitle(_ text: String) async {
        titleText = text
        await presentFetchedData()
    }

    func handleChangeDescription(_ text: String) async {
        descriptionText = text
        await presentFetchedData()
    }

    func handleTapCategory() async {
        await router.openCategoryPicker(
            selectedCategoryID: selectedCategory?.id,
            output: self
        )
    }

    func handleTapConfirm() async {
        await router.presentComingSoon()
    }

    func handleTapClose() async {
        await router.close()
    }
}

extension ExpenseManualEntryInteractor: ExpenseCategoryPickerOutput {
    func handleDidSelectCategory(_ category: ExpenseCategorySelectionModel) async {
        selectedCategory = category
        await presentFetchedData()
    }
}
