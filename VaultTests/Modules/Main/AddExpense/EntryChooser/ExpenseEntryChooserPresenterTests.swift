import XCTest
@testable import Vault

@MainActor
final class ExpenseEntryChooserPresenterTests: XCTestCase {
    private var sut: ExpenseEntryChooserPresenter!
    private var handler: ExpenseEntryChooserHandlerSpy!

    override func setUp() {
        super.setUp()
        handler = ExpenseEntryChooserHandlerSpy()
        sut = ExpenseEntryChooserPresenter(viewModel: .init())
        sut.handler = handler
    }

    override func tearDown() {
        handler = nil
        sut = nil
        super.tearDown()
    }

    func testPresentFetchedDataBuildsChooserButtons() {
        sut.presentFetchedData(.init())

        XCTAssertEqual(sut.viewModel.header.title.text, L10n.mainAddExpenseTitle)
        XCTAssertEqual(sut.viewModel.aiButton.title, L10n.expenseEntryChooserEnterWithAi)
        XCTAssertEqual(sut.viewModel.manualButton.title, L10n.expenseEntryChooserEnterManually)
    }
}

private final class ExpenseEntryChooserHandlerSpy: ExpenseEntryChooserHandler, @unchecked Sendable {
    func handleTapClose() async {}
    func handleTapAiEntry() async {}
    func handleTapManualEntry() async {}
}
