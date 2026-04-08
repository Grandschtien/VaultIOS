import XCTest
@testable import Vault

@MainActor
final class CategoryPeriodPickerPresenterTests: XCTestCase {
    func testPresentFetchedDataBuildsViewModel() {
        let sut = CategoryPeriodPickerPresenter(viewModel: .init())
        let fromDate = Date(timeIntervalSince1970: 100)
        let toDate = Date(timeIntervalSince1970: 200)
        let minimumDate = Date(timeIntervalSince1970: 10)
        let maximumDate = Date(timeIntervalSince1970: 300)

        sut.presentFetchedData(
            .init(
                fromDate: fromDate,
                toDate: toDate,
                activeField: .to,
                selectedCalendarDate: toDate,
                visibleMonthDate: minimumDate,
                minimumDate: minimumDate,
                maximumDate: maximumDate,
                isApplyEnabled: false
            )
        )

        XCTAssertEqual(sut.viewModel.navigationTitle.text, L10n.categoryPeriodPickerTitle)
        XCTAssertEqual(sut.viewModel.fromField.title.text, L10n.categoryPeriodPickerFrom)
        XCTAssertEqual(sut.viewModel.toField.title.text, L10n.categoryPeriodPickerTo)
        XCTAssertFalse(sut.viewModel.fromField.isActive)
        XCTAssertTrue(sut.viewModel.toField.isActive)
        XCTAssertEqual(sut.viewModel.calendar.selectedDate, toDate)
        XCTAssertEqual(sut.viewModel.calendar.visibleMonthDate, minimumDate)
        XCTAssertEqual(sut.viewModel.calendar.minimumDate, minimumDate)
        XCTAssertEqual(sut.viewModel.calendar.maximumDate, maximumDate)
        XCTAssertEqual(sut.viewModel.confirmButton.title, L10n.categoryPeriodPickerApply)
        XCTAssertFalse(sut.viewModel.confirmButton.isEnabled)
        XCTAssertNotEqual(sut.viewModel.closeButton.tapCommand, .nope)
        XCTAssertNotEqual(sut.viewModel.confirmButton.tapCommand, .nope)
        XCTAssertNotEqual(sut.viewModel.fromField.tapCommand, .nope)
        XCTAssertNotEqual(sut.viewModel.toField.tapCommand, .nope)
        XCTAssertNotEqual(
            sut.viewModel.calendar.selectionCommand,
            CommandOf<Date>(action: nil)
        )
    }
}
