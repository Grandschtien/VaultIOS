import XCTest
@testable import Vault

@MainActor
final class CategoryPeriodPickerInteractorTests: XCTestCase {
    func testHandleTapConfirmSendsSelectedDateAndCloses() async {
        let presenter = CategoryPeriodPickerPresenterSpy()
        let router = CategoryPeriodPickerRouterSpy()
        let output = CategoryPeriodPickerOutputSpy()
        let calendar = Calendar(identifier: .gregorian)
        let initialDate = calendar.date(
            from: DateComponents(
                calendar: calendar,
                year: 2026,
                month: 4,
                day: 1
            )
        )!
        let updatedDate = calendar.date(
            from: DateComponents(
                calendar: calendar,
                year: 2026,
                month: 4,
                day: 5,
                hour: 13
            )
        )!
        let sut = CategoryPeriodPickerInteractor(
            presenter: presenter,
            router: router,
            output: output,
            selectedDate: initialDate,
            calendar: calendar
        )

        await sut.fetchData()
        await sut.handleSelectDate(updatedDate)
        await sut.handleTapConfirm()

        XCTAssertEqual(output.selectedDates, [calendar.startOfDay(for: updatedDate)])
        XCTAssertEqual(router.closeCallCount, 1)
        XCTAssertEqual(presenter.presentedData.last?.selectedDate, calendar.startOfDay(for: updatedDate))
    }
}

@MainActor
private final class CategoryPeriodPickerPresenterSpy: CategoryPeriodPickerPresentationLogic, @unchecked Sendable {
    private(set) var presentedData: [CategoryPeriodPickerFetchData] = []

    func presentFetchedData(_ data: CategoryPeriodPickerFetchData) {
        presentedData.append(data)
    }
}

@MainActor
private final class CategoryPeriodPickerRouterSpy: CategoryPeriodPickerRoutingLogic, @unchecked Sendable {
    private(set) var closeCallCount: Int = .zero

    func close() {
        closeCallCount += 1
    }
}

private final class CategoryPeriodPickerOutputSpy: CategoryPeriodPickerOutput, @unchecked Sendable {
    @MainActor
    private(set) var selectedDates: [Date] = []

    func handleDidConfirmCategoryPeriod(fromDate: Date) async {
        await MainActor.run {
            selectedDates.append(fromDate)
        }
    }
}
