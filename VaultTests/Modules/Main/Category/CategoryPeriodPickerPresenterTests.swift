import XCTest
@testable import Vault

@MainActor
final class CategoryPeriodPickerPresenterTests: XCTestCase {
    func testPresentFetchedDataBuildsViewModel() {
        let sut = CategoryPeriodPickerPresenter(viewModel: .init())
        let selectedDate = Date(timeIntervalSince1970: 100)
        let minimumDate = Date(timeIntervalSince1970: 10)
        let maximumDate = Date(timeIntervalSince1970: 200)

        sut.presentFetchedData(
            .init(
                selectedDate: selectedDate,
                minimumDate: minimumDate,
                maximumDate: maximumDate
            )
        )

        XCTAssertEqual(sut.viewModel.navigationTitle.text, L10n.categoryPeriodPickerTitle)
        XCTAssertEqual(sut.viewModel.calendar.selectedDate, selectedDate)
        XCTAssertEqual(sut.viewModel.calendar.minimumDate, minimumDate)
        XCTAssertEqual(sut.viewModel.calendar.maximumDate, maximumDate)
        XCTAssertEqual(sut.viewModel.confirmButton.title, L10n.categoryPeriodPickerApply)
        XCTAssertNotEqual(sut.viewModel.closeButton.tapCommand, .nope)
        XCTAssertNotEqual(sut.viewModel.confirmButton.tapCommand, .nope)
        XCTAssertNotEqual(
            sut.viewModel.calendar.selectionCommand,
            CommandOf<Date>(action: nil)
        )
    }
}
