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
                maximumCharacters: 280,
                isProcessEnabled: true
            )
        )

        XCTAssertEqual(sut.viewModel.promptInput.counter?.text, "6/280")
        XCTAssertEqual(sut.viewModel.processButton.title, L10n.expenseAiEntryProcess)
        XCTAssertTrue(sut.viewModel.processButton.isEnabled)
    }

    func testPresentFetchedDataShowsLoadingAndDisablesClose() {
        sut.presentFetchedData(
            .init(
                promptText: "Coffee",
                loadingState: .loading,
                isPromptEditable: false,
                isCloseEnabled: false,
                isProcessEnabled: true
            )
        )

        XCTAssertTrue(sut.viewModel.processButton.isLoading)
        XCTAssertFalse(sut.viewModel.processButton.isEnabled)
        XCTAssertFalse(sut.viewModel.header.isCloseEnabled)
        XCTAssertFalse(sut.viewModel.promptInput.isEditable)
    }

    func testPresentFetchedDataBuildsHeaderTitle() {
        sut.presentFetchedData(
            .init(
                title: L10n.expenseAiEntryTitle
            )
        )

        XCTAssertEqual(sut.viewModel.header.title.text, L10n.expenseAiEntryTitle)
        XCTAssertEqual(sut.viewModel.promptInput.placeholder, L10n.expenseAiEntryPlaceholder)
    }
}

private final class ExpenseAIEntryHandlerSpy: ExpenseAIEntryHandler, @unchecked Sendable {
    func handleChangePrompt(_ text: String) async {}
    func handleTapProcess() async {}
    func handleTapClose() async {}
    func handleTapAddManually() async {}
    func handleTapFixPrompt() async {}
}
