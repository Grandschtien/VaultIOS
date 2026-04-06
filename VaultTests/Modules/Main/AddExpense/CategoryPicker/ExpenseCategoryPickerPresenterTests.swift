import XCTest
@testable import Vault

@MainActor
final class ExpenseCategoryPickerPresenterTests: XCTestCase {
    private var sut: ExpenseCategoryPickerPresenter!
    private var handler: ExpenseCategoryPickerHandlerSpy!

    override func setUp() {
        super.setUp()
        handler = ExpenseCategoryPickerHandlerSpy()
        sut = ExpenseCategoryPickerPresenter(
            viewModel: .init(),
            colorProvider: CategoryColorProvider()
        )
        sut.handler = handler
    }

    override func tearDown() {
        handler = nil
        sut = nil
        super.tearDown()
    }

    func testPresentFetchedDataBuildsLoadingRows() {
        sut.presentFetchedData(
            .init(
                loadingState: .loading
            )
        )

        guard case let .loading(rows) = sut.viewModel.state else {
            return XCTFail("Expected loading state")
        }

        XCTAssertEqual(rows.count, 6)
        XCTAssertTrue(rows.allSatisfy(\.isLoading))
    }

    func testPresentFetchedDataBuildsEmptyState() {
        sut.presentFetchedData(
            .init(
                loadingState: .loaded,
                categories: []
            )
        )

        guard case let .empty(label) = sut.viewModel.state else {
            return XCTFail("Expected empty state")
        }

        XCTAssertEqual(label.text, L10n.expenseCategoryPickerEmpty)
        XCTAssertFalse(sut.viewModel.addButton.isEnabled)
    }

    func testPresentFetchedDataBuildsLoadedRowsWithSelection() {
        sut.presentFetchedData(
            .init(
                loadingState: .loaded,
                categories: [
                    .init(id: "food", name: "Food", icon: "🍔", color: "green"),
                    .init(id: "car", name: "Car", icon: "🚗", color: "blue")
                ],
                selectedCategoryID: "car"
            )
        )

        guard case let .loaded(rows) = sut.viewModel.state else {
            return XCTFail("Expected loaded state")
        }

        XCTAssertEqual(rows.count, 2)
        XCTAssertEqual(rows.last?.isSelected, true)
        XCTAssertTrue(sut.viewModel.addButton.isEnabled)
    }
}

private final class ExpenseCategoryPickerHandlerSpy: ExpenseCategoryPickerHandler, @unchecked Sendable {
    func handleTapCategory(id: String) async {}
    func handleTapAdd() async {}
    func handleTapCreateCategory() async {}
    func handleTapRetry() async {}
    func handleTapClose() async {}
}
