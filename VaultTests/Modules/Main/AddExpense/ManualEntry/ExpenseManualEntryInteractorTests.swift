import XCTest
@testable import Vault

@MainActor
final class ExpenseManualEntryInteractorTests: XCTestCase {
    func testFetchDataBuildsEmptyDraft() async {
        let presenter = ExpenseManualEntryPresenterSpy()
        let router = ExpenseManualEntryRouterSpy()
        let sut = ExpenseManualEntryInteractor(
            presenter: presenter,
            router: router
        )

        await sut.fetchData()

        let last = presenter.presentedData.last
        XCTAssertEqual(last?.amountText, "")
        XCTAssertEqual(last?.titleText, "")
        XCTAssertEqual(last?.descriptionText, "")
        XCTAssertNil(last?.selectedCategory)
    }

    func testHandleFieldChangesUpdateDraft() async {
        let presenter = ExpenseManualEntryPresenterSpy()
        let router = ExpenseManualEntryRouterSpy()
        let sut = ExpenseManualEntryInteractor(
            presenter: presenter,
            router: router
        )

        await sut.handleChangeAmount("45.00")
        await sut.handleChangeTitle("Lunch at Nando's")
        await sut.handleChangeDescription("Quick lunch after the project milestone.")

        let last = presenter.presentedData.last
        XCTAssertEqual(last?.amountText, "45.00")
        XCTAssertEqual(last?.titleText, "Lunch at Nando's")
        XCTAssertEqual(last?.descriptionText, "Quick lunch after the project milestone.")
    }

    func testHandleTapCategoryOpensPicker() async {
        let presenter = ExpenseManualEntryPresenterSpy()
        let router = ExpenseManualEntryRouterSpy()
        let sut = ExpenseManualEntryInteractor(
            presenter: presenter,
            router: router
        )

        await sut.handleTapCategory()

        XCTAssertEqual(router.openCategoryPickerCallsCount, 1)
        XCTAssertNil(router.lastSelectedCategoryID)
    }

    func testHandleDidSelectCategoryUpdatesDraft() async {
        let presenter = ExpenseManualEntryPresenterSpy()
        let router = ExpenseManualEntryRouterSpy()
        let sut = ExpenseManualEntryInteractor(
            presenter: presenter,
            router: router
        )

        await sut.handleDidSelectCategory(
            .init(
                id: "food",
                name: "Food & Dining",
                icon: "🍔",
                color: "green"
            )
        )

        XCTAssertEqual(presenter.presentedData.last?.selectedCategory?.id, "food")
        XCTAssertEqual(presenter.presentedData.last?.selectedCategory?.name, "Food & Dining")
    }

    func testHandleTapConfirmShowsComingSoonToast() async {
        let presenter = ExpenseManualEntryPresenterSpy()
        let router = ExpenseManualEntryRouterSpy()
        let sut = ExpenseManualEntryInteractor(
            presenter: presenter,
            router: router
        )

        await sut.handleTapConfirm()

        XCTAssertEqual(router.presentComingSoonCallsCount, 1)
    }
}

@MainActor
private final class ExpenseManualEntryPresenterSpy: ExpenseManualEntryPresentationLogic {
    private(set) var presentedData: [ExpenseManualEntryFetchData] = []

    func presentFetchedData(_ data: ExpenseManualEntryFetchData) {
        presentedData.append(data)
    }
}

@MainActor
private final class ExpenseManualEntryRouterSpy: ExpenseManualEntryRoutingLogic {
    private(set) var openCategoryPickerCallsCount = 0
    private(set) var closeCallsCount = 0
    private(set) var presentComingSoonCallsCount = 0
    private(set) var lastSelectedCategoryID: String?

    func openCategoryPicker(
        selectedCategoryID: String?,
        output: ExpenseCategoryPickerOutput
    ) {
        openCategoryPickerCallsCount += 1
        lastSelectedCategoryID = selectedCategoryID
    }

    func close() {
        closeCallsCount += 1
    }

    func presentComingSoon() {
        presentComingSoonCallsCount += 1
    }
}
