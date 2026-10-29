import XCTest
@testable import Vylok

@MainActor
final class CategoryPeriodPickerInteractorTests: XCTestCase {
    func testFetchDataShowsInitialRangeWithActiveFromField() async {
        let presenter = CategoryPeriodPickerPresentationLogicMock()
        let router = CategoryPeriodPickerRoutingLogicMock()
        let output = CategoryPeriodPickerOutputMock()
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

        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.fromDate, currentMonthStart)
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.toDate, now)
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.activeField, .from)
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.selectedCalendarDate, currentMonthStart)
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.visibleMonthDate, currentMonthStart)
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.maximumDate, now)
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.isApplyEnabled, true)
        XCTAssertEqual(router.closeCallsCount, 0)
        XCTAssertTrue(output.handleDidConfirmCategoryPeriodFromDateToReceivedInvocations.map { MainSummaryPeriod(from: $0.fromDate, to: $0.date) }.isEmpty)
    }
}

extension CategoryPeriodPickerInteractorTests {
    func testHandleTapFromFieldSwitchesActiveFieldAndCalendarSelection() async {
        let presenter = CategoryPeriodPickerPresentationLogicMock()
        let router = CategoryPeriodPickerRoutingLogicMock()
        let output = CategoryPeriodPickerOutputMock()
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

        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.activeField, .from)
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.selectedCalendarDate, currentMonthStart)
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.visibleMonthDate, currentMonthStart)
    }

    func testInvalidRangeDisablesApplyUntilUserSelectsValidToDate() async {
        let presenter = CategoryPeriodPickerPresentationLogicMock()
        let router = CategoryPeriodPickerRoutingLogicMock()
        let output = CategoryPeriodPickerOutputMock()
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
        await sut.handleTapToField()
        await sut.handleSelectDate(invalidToDate)
        await sut.handleTapFromField()
        await sut.handleSelectDate(invalidFromDate)
        await sut.handleTapConfirm()

        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.isApplyEnabled, false)
        XCTAssertEqual(router.closeCallsCount, 0)
        XCTAssertTrue(output.handleDidConfirmCategoryPeriodFromDateToReceivedInvocations.map { MainSummaryPeriod(from: $0.fromDate, to: $0.date) }.isEmpty)

        await sut.handleTapToField()
        await sut.handleSelectDate(validToDate)

        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.isApplyEnabled, true)
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.activeField, .to)
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.selectedCalendarDate, expectedValidCalendarSelection)
    }

    func testHandleTapConfirmReturnsNormalizedExplicitRange() async {
        let presenter = CategoryPeriodPickerPresentationLogicMock()
        let router = CategoryPeriodPickerRoutingLogicMock()
        let output = CategoryPeriodPickerOutputMock()
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
            output.handleDidConfirmCategoryPeriodFromDateToReceivedInvocations.map { MainSummaryPeriod(from: $0.fromDate, to: $0.date) },
            [
                .init(
                    from: calendar.startOfDay(for: selectedFromDate),
                    to: expectedToDate
                )
            ]
        )
        XCTAssertEqual(router.closeCallsCount, 1)
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
