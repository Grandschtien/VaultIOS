import XCTest
@testable import Vault

@MainActor
final class ExpenseAIEntryPresenterTests: XCTestCase {
    private var sut: ExpenseAIEntryPresenter!
    private var handler: ExpenseAIEntryHandlerSpy!

    override func setUp() {
        super.setUp()
        handler = ExpenseAIEntryHandlerSpy()
        sut = ExpenseAIEntryPresenter(viewModel: .init())
        sut.handler = handler
    }

    override func tearDown() {
        handler = nil
        sut = nil
        super.tearDown()
    }

    func testPresentFetchedDataBuildsCounterAndProcessButton() {
        sut.presentFetchedData(
            .init(
                promptText: "Coffee",
                maximumCharacters: 280
            )
        )

        XCTAssertEqual(sut.viewModel.promptInput.counter?.text, "6/280")
        XCTAssertEqual(sut.viewModel.processButton.title, L10n.expenseAiEntryProcess)
    }
}

private final class ExpenseAIEntryHandlerSpy: ExpenseAIEntryHandler, @unchecked Sendable {
    func handleChangePrompt(_ text: String) async {}
    func handleTapProcess() async {}
    func handleTapClose() async {}
}
