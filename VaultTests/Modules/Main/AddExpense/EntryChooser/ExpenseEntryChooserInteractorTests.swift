import XCTest
@testable import Vault

@MainActor
final class ExpenseEntryChooserInteractorTests: XCTestCase {
    func testFetchDataPresentsDefaultTitle() async {
        let presenter = ExpenseEntryChooserPresenterSpy()
        let router = ExpenseEntryChooserRouterSpy()
        let sut = ExpenseEntryChooserInteractor(
            presenter: presenter,
            router: router
        )

        await sut.fetchData()

        XCTAssertEqual(presenter.presentedData.last?.title, L10n.mainAddExpenseTitle)
    }

    func testHandleTapAiEntryRoutesToAiScreen() async {
        let router = ExpenseEntryChooserRouterSpy()
        let sut = ExpenseEntryChooserInteractor(
            presenter: ExpenseEntryChooserPresenterSpy(),
            router: router
        )

        await sut.handleTapAiEntry()

        XCTAssertEqual(router.openAiEntryCallsCount, 1)
    }

    func testHandleTapManualEntryRoutesToManualScreen() async {
        let router = ExpenseEntryChooserRouterSpy()
        let sut = ExpenseEntryChooserInteractor(
            presenter: ExpenseEntryChooserPresenterSpy(),
            router: router
        )

        await sut.handleTapManualEntry()

        XCTAssertEqual(router.openManualEntryCallsCount, 1)
    }

    func testHandleTapCloseDismissesSheet() async {
        let router = ExpenseEntryChooserRouterSpy()
        let sut = ExpenseEntryChooserInteractor(
            presenter: ExpenseEntryChooserPresenterSpy(),
            router: router
        )

        await sut.handleTapClose()

        XCTAssertEqual(router.closeCallsCount, 1)
    }
}

@MainActor
private final class ExpenseEntryChooserPresenterSpy: ExpenseEntryChooserPresentationLogic {
    private(set) var presentedData: [ExpenseEntryChooserFetchData] = []

    func presentFetchedData(_ data: ExpenseEntryChooserFetchData) {
        presentedData.append(data)
    }
}

@MainActor
private final class ExpenseEntryChooserRouterSpy: ExpenseEntryChooserRoutingLogic {
    private(set) var openAiEntryCallsCount = 0
    private(set) var openManualEntryCallsCount = 0
    private(set) var closeCallsCount = 0

    func openAiEntry() {
        openAiEntryCallsCount += 1
    }

    func openManualEntry() {
        openManualEntryCallsCount += 1
    }

    func close() {
        closeCallsCount += 1
    }
}
