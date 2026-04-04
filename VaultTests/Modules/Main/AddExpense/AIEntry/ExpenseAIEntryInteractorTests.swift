import XCTest
@testable import Vault

@MainActor
final class ExpenseAIEntryInteractorTests: XCTestCase {
    func testFetchDataBuildsEmptyPromptState() async {
        let presenter = ExpenseAIEntryPresenterSpy()
        let router = ExpenseAIEntryRouterSpy()
        let sut = ExpenseAIEntryInteractor(
            presenter: presenter,
            router: router
        )

        await sut.fetchData()

        XCTAssertEqual(presenter.presentedData.last?.promptText, "")
        XCTAssertEqual(presenter.presentedData.last?.maximumCharacters, 280)
    }

    func testHandleChangePromptTrimsTextToMaximumCharacters() async {
        let presenter = ExpenseAIEntryPresenterSpy()
        let router = ExpenseAIEntryRouterSpy()
        let sut = ExpenseAIEntryInteractor(
            presenter: presenter,
            router: router
        )

        await sut.handleChangePrompt(String(repeating: "a", count: 400))

        XCTAssertEqual(presenter.presentedData.last?.promptText.count, 280)
    }

    func testHandleTapProcessShowsComingSoonToast() async {
        let presenter = ExpenseAIEntryPresenterSpy()
        let router = ExpenseAIEntryRouterSpy()
        let sut = ExpenseAIEntryInteractor(
            presenter: presenter,
            router: router
        )

        await sut.handleTapProcess()

        XCTAssertEqual(router.presentComingSoonCallsCount, 1)
    }
}

@MainActor
private final class ExpenseAIEntryPresenterSpy: ExpenseAIEntryPresentationLogic {
    private(set) var presentedData: [ExpenseAIEntryFetchData] = []

    func presentFetchedData(_ data: ExpenseAIEntryFetchData) {
        presentedData.append(data)
    }
}

@MainActor
private final class ExpenseAIEntryRouterSpy: ExpenseAIEntryRoutingLogic {
    private(set) var closeCallsCount = 0
    private(set) var presentComingSoonCallsCount = 0

    func close() {
        closeCallsCount += 1
    }

    func presentComingSoon() {
        presentComingSoonCallsCount += 1
    }
}
