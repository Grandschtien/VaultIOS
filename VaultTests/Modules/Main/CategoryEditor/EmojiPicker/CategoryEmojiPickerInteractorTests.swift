import XCTest
@testable import Vault

@MainActor
final class CategoryEmojiPickerInteractorTests: XCTestCase {
    func testFetchDataBuildsFullCatalog() async {
        let presenter = CategoryEmojiPickerPresenterSpy()
        let sut = makeSUT(
            presenter: presenter
        )

        await sut.fetchData()

        let data = tryUnwrap(presenter.presentedData.last)
        XCTAssertEqual(data.selectedEmoji, "🍽️")
        XCTAssertEqual(data.emojis.count, CategoryEditorPresetProvider().emojiCatalog().count)
    }

    func testHandleChangeSearchQueryFiltersEmojiCatalog() async {
        let presenter = CategoryEmojiPickerPresenterSpy()
        let sut = makeSUT(
            presenter: presenter
        )

        await sut.fetchData()
        await sut.handleChangeSearchQuery("travel")

        let data = tryUnwrap(presenter.presentedData.last)
        XCTAssertEqual(data.emojis.map(\.emoji), ["🚗", "✈️"])
    }

    func testHandleTapEmojiNotifiesOutputAndCloses() async {
        let presenter = CategoryEmojiPickerPresenterSpy()
        let router = CategoryEmojiPickerRouterSpy()
        let output = CategoryEmojiPickerOutputSpy()
        let sut = makeSUT(
            presenter: presenter,
            router: router,
            output: output
        )

        await sut.fetchData()
        await sut.handleTapEmoji("🎁")

        XCTAssertEqual(output.selectedEmoji, "🎁")
        XCTAssertEqual(router.closeCallsCount, 1)
    }
}

@MainActor
final class CategoryEmojiPickerPresenterTests: XCTestCase {
    func testPresentFetchedDataBuildsEmptyStateWhenNoResults() {
        let sut = CategoryEmojiPickerPresenter(viewModel: .init())

        sut.presentFetchedData(
            .init(
                searchQuery: "zzz",
                selectedEmoji: "🍽️",
                emojis: []
            )
        )

        guard case let .empty(label) = sut.viewModel.state else {
            return XCTFail("Expected empty state")
        }

        XCTAssertEqual(label.text, L10n.categoryEmojiPickerEmpty)
    }
}

private extension CategoryEmojiPickerInteractorTests {
    func makeSUT(
        presenter: CategoryEmojiPickerPresenterSpy,
        router: CategoryEmojiPickerRouterSpy? = nil,
        output: CategoryEmojiPickerOutputSpy = .init()
    ) -> CategoryEmojiPickerInteractor {
        let resolvedRouter = router ?? CategoryEmojiPickerRouterSpy()

        return CategoryEmojiPickerInteractor(
            selectedEmoji: "🍽️",
            presenter: presenter,
            router: resolvedRouter,
            output: output,
            presetProvider: CategoryEditorPresetProvider()
        )
    }

    func tryUnwrap<T>(
        _ value: T?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> T {
        guard let value else {
            XCTFail("Expected value", file: file, line: line)
            fatalError("Missing expected value")
        }

        return value
    }
}

@MainActor
private final class CategoryEmojiPickerPresenterSpy: CategoryEmojiPickerPresentationLogic {
    private(set) var presentedData: [CategoryEmojiPickerFetchData] = []

    func presentFetchedData(_ data: CategoryEmojiPickerFetchData) {
        presentedData.append(data)
    }
}

@MainActor
private final class CategoryEmojiPickerRouterSpy: CategoryEmojiPickerRoutingLogic {
    private(set) var closeCallsCount = 0

    func close() {
        closeCallsCount += 1
    }
}

private final class CategoryEmojiPickerOutputSpy: CategoryEmojiPickerOutput, @unchecked Sendable {
    private(set) var selectedEmoji: String?

    func handleDidSelectEmoji(_ emoji: String) async {
        selectedEmoji = emoji
    }
}
