import XCTest
@testable import Vault

@MainActor
final class CategoryPeriodPickerInteractorTests: XCTestCase {
    func testFetchDataShowsInitialRangeWithActiveToField() async {
        let presenter = CategoryPeriodPickerPresenterSpy()
        let router = CategoryPeriodPickerRouterSpy()
        let output = CategoryPeriodPickerOutputSpy()
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 4, day: 16, hour: 11, minute: 30, calendar: calendar)
        let currentMonthStart = makeDate(year: 2026, month: 4, day: 1, calendar: calendar)
        let sut = makeSut(
            presenter: presenter,
            router: router,
            output: output,
            fromDate: currentMonthStart,
            toDate: now,
            calendar: calendar,
            now: now
        )

        await sut.fetchData()

        XCTAssertEqual(presenter.presentedData.last?.fromDate, currentMonthStart)
        XCTAssertEqual(presenter.presentedData.last?.toDate, now)
        XCTAssertEqual(presenter.presentedData.last?.activeField, .to)
        XCTAssertEqual(presenter.presentedData.last?.selectedCalendarDate, now)
        XCTAssertEqual(presenter.presentedData.last?.visibleMonthDate, currentMonthStart)
        XCTAssertEqual(presenter.presentedData.last?.maximumDate, now)
        XCTAssertEqual(presenter.presentedData.last?.isApplyEnabled, true)
        XCTAssertEqual(router.closeCallCount, 0)
        XCTAssertTrue(output.selectedPeriods.isEmpty)
    }
}

extension CategoryPeriodPickerInteractorTests {
    func testHandleTapFromFieldSwitchesActiveFieldAndCalendarSelection() async {
        let presenter = CategoryPeriodPickerPresenterSpy()
        let router = CategoryPeriodPickerRouterSpy()
        let output = CategoryPeriodPickerOutputSpy()
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 4, day: 16, hour: 11, minute: 30, calendar: calendar)
        let currentMonthStart = makeDate(year: 2026, month: 4, day: 1, calendar: calendar)
        let sut = makeSut(
            presenter: presenter,
            router: router,
            output: output,
            fromDate: currentMonthStart,
            toDate: now,
            calendar: calendar,
            now: now
        )

        await sut.fetchData()
        await sut.handleTapFromField()

        XCTAssertEqual(presenter.presentedData.last?.activeField, .from)
        XCTAssertEqual(presenter.presentedData.last?.selectedCalendarDate, currentMonthStart)
        XCTAssertEqual(presenter.presentedData.last?.visibleMonthDate, currentMonthStart)
    }

    func testInvalidRangeDisablesApplyUntilUserSelectsValidToDate() async {
        let presenter = CategoryPeriodPickerPresenterSpy()
        let router = CategoryPeriodPickerRouterSpy()
        let output = CategoryPeriodPickerOutputSpy()
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 4, day: 16, hour: 11, minute: 30, calendar: calendar)
        let currentMonthStart = makeDate(year: 2026, month: 4, day: 1, calendar: calendar)
        let invalidFromDate = makeDate(year: 2026, month: 4, day: 12, calendar: calendar)
        let invalidToDate = makeDate(year: 2026, month: 4, day: 10, calendar: calendar)
        let validToDate = makeDate(year: 2026, month: 4, day: 15, calendar: calendar)
        let expectedValidCalendarSelection = calendar.dateInterval(of: .day, for: validToDate)?.end.addingTimeInterval(-1) ?? .distantPast
        let sut = makeSut(
            presenter: presenter,
            router: router,
            output: output,
            fromDate: currentMonthStart,
            toDate: now,
            calendar: calendar,
            now: now
        )

        await sut.fetchData()
        await sut.handleSelectDate(invalidToDate)
        await sut.handleTapFromField()
        await sut.handleSelectDate(invalidFromDate)
        await sut.handleTapConfirm()

        XCTAssertEqual(presenter.presentedData.last?.isApplyEnabled, false)
        XCTAssertEqual(router.closeCallCount, 0)
        XCTAssertTrue(output.selectedPeriods.isEmpty)

        await sut.handleTapToField()
        await sut.handleSelectDate(validToDate)

        XCTAssertEqual(presenter.presentedData.last?.isApplyEnabled, true)
        XCTAssertEqual(presenter.presentedData.last?.activeField, .to)
        XCTAssertEqual(presenter.presentedData.last?.selectedCalendarDate, expectedValidCalendarSelection)
    }

    func testHandleTapConfirmReturnsNormalizedExplicitRange() async {
        let presenter = CategoryPeriodPickerPresenterSpy()
        let router = CategoryPeriodPickerRouterSpy()
        let output = CategoryPeriodPickerOutputSpy()
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 4, day: 16, hour: 11, minute: 30, calendar: calendar)
        let currentMonthStart = makeDate(year: 2026, month: 4, day: 1, calendar: calendar)
        let selectedFromDate = makeDate(year: 2026, month: 4, day: 5, hour: 13, calendar: calendar)
        let selectedToDate = makeDate(year: 2026, month: 4, day: 10, hour: 15, calendar: calendar)
        let expectedToDate = calendar.dateInterval(of: .day, for: selectedToDate)?.end.addingTimeInterval(-1) ?? .distantPast
        let sut = makeSut(
            presenter: presenter,
            router: router,
            output: output,
            fromDate: currentMonthStart,
            toDate: now,
            calendar: calendar,
            now: now
        )

        await sut.fetchData()
        await sut.handleTapFromField()
        await sut.handleSelectDate(selectedFromDate)
        await sut.handleTapToField()
        await sut.handleSelectDate(selectedToDate)
        await sut.handleTapConfirm()

        XCTAssertEqual(
            output.selectedPeriods,
            [
                .init(
                    from: calendar.startOfDay(for: selectedFromDate),
                    to: expectedToDate
                )
            ]
        )
        XCTAssertEqual(router.closeCallCount, 1)
    }
}

private extension CategoryPeriodPickerInteractorTests {
    func makeSut(
        presenter: CategoryPeriodPickerPresentationLogic,
        router: CategoryPeriodPickerRoutingLogic,
        output: CategoryPeriodPickerOutput,
        fromDate: Date,
        toDate: Date,
        calendar: Calendar,
        now: Date
    ) -> CategoryPeriodPickerInteractor {
        CategoryPeriodPickerInteractor(
            presenter: presenter,
            router: router,
            output: output,
            fromDate: fromDate,
            toDate: toDate,
            calendar: calendar,
            now: { now }
        )
    }

    func makeCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: .zero) ?? .current
        return calendar
    }

    func makeDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = .zero,
        minute: Int = .zero,
        calendar: Calendar
    ) -> Date {
        calendar.date(
            from: DateComponents(
                timeZone: calendar.timeZone,
                year: year,
                month: month,
                day: day,
                hour: hour,
                minute: minute
            )
        ) ?? .distantPast
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
    private(set) var selectedPeriods: [MainSummaryPeriod] = []

    func handleDidConfirmCategoryPeriod(fromDate: Date, to date: Date) async {
        await MainActor.run {
            selectedPeriods.append(
                .init(
                    from: fromDate,
                    to: date
                )
            )
        }
    }
}
