import XCTest
@testable import Vault

final class MainSummaryPeriodProviderTests: XCTestCase {
    func testCurrentMonthPeriodStartsFromFirstDayOfMonthAndEndsAtCurrentDate() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: .zero) ?? .current

        let now = calendar.date(from: DateComponents(
            timeZone: calendar.timeZone,
            year: 2025,
            month: 1,
            day: 11,
            hour: 23,
            minute: 50
        )) ?? .distantPast
        let sut = MainSummaryPeriodProvider(
            calendar: calendar,
            now: { now }
        )

        let period = sut.currentMonthPeriod()

        XCTAssertEqual(
            period.from,
            calendar.date(from: DateComponents(
                timeZone: calendar.timeZone,
                year: 2025,
                month: 1,
                day: 1
            ))
        )
        XCTAssertEqual(period.to, now)
    }
}

extension MainSummaryPeriodProviderTests {
    func testCurrentMonthPeriodKeepsFirstDayWhenNowIsAlreadyAtMonthStart() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: .zero) ?? .current

        let now = calendar.date(from: DateComponents(
            timeZone: calendar.timeZone,
            year: 2025,
            month: 4,
            day: 1,
            hour: 8,
            minute: 30
        )) ?? .distantPast
        let sut = MainSummaryPeriodProvider(
            calendar: calendar,
            now: { now }
        )

        let period = sut.currentMonthPeriod()

        XCTAssertEqual(
            period.from,
            calendar.date(from: DateComponents(
                timeZone: calendar.timeZone,
                year: 2025,
                month: 4,
                day: 1
            ))
        )
        XCTAssertEqual(period.to, now)
    }

    func testCurrentMonthPeriodUsesUpdatedCurrentMonthDayWhenUserSelectsCustomPeriod() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: .zero) ?? .current

        let now = calendar.date(from: DateComponents(
            timeZone: calendar.timeZone,
            year: 2025,
            month: 4,
            day: 11,
            hour: 8,
            minute: 30
        )) ?? .distantPast
        let selectedDate = calendar.date(from: DateComponents(
            timeZone: calendar.timeZone,
            year: 2025,
            month: 4,
            day: 3,
            hour: 21,
            minute: 15
        )) ?? .distantPast
        let sut = MainSummaryPeriodProvider(
            calendar: calendar,
            now: { now }
        )

        sut.updatePeriod(from: selectedDate, to: now)
        let period = sut.currentMonthPeriod()

        XCTAssertEqual(
            period.from,
            calendar.date(from: DateComponents(
                timeZone: calendar.timeZone,
                year: 2025,
                month: 4,
                day: 3
            ))
        )
        XCTAssertEqual(period.to, now)
    }
}

extension MainSummaryPeriodProviderTests {
    func testCurrentMonthPeriodUsesSelectedPreviousMonthDayUntilEndOfMonth() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: .zero) ?? .current

        let now = calendar.date(from: DateComponents(
            timeZone: calendar.timeZone,
            year: 2025,
            month: 4,
            day: 16,
            hour: 8,
            minute: 30
        )) ?? .distantPast
        let selectedDate = calendar.date(from: DateComponents(
            timeZone: calendar.timeZone,
            year: 2025,
            month: 3,
            day: 15,
            hour: 21,
            minute: 15
        )) ?? .distantPast
        let expectedMonthEnd = calendar.dateInterval(of: .month, for: selectedDate)?.end.addingTimeInterval(-1)
        let sut = MainSummaryPeriodProvider(
            calendar: calendar,
            now: { now }
        )

        sut.updatePeriod(from: selectedDate, to: expectedMonthEnd ?? now)
        let period = sut.currentMonthPeriod()

        XCTAssertEqual(
            period.from,
            calendar.date(from: DateComponents(
                timeZone: calendar.timeZone,
                year: 2025,
                month: 3,
                day: 15
            ))
        )
        XCTAssertEqual(period.to, expectedMonthEnd)
    }

    func testCurrentMonthPeriodUsesFullPreviousMonthWhenUserSelectsMonthOnly() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: .zero) ?? .current

        let now = calendar.date(from: DateComponents(
            timeZone: calendar.timeZone,
            year: 2025,
            month: 4,
            day: 16,
            hour: 8,
            minute: 30
        )) ?? .distantPast
        let selectedMonthStart = calendar.date(from: DateComponents(
            timeZone: calendar.timeZone,
            year: 2025,
            month: 3,
            day: 1
        )) ?? .distantPast
        let expectedMonthEnd = calendar.dateInterval(of: .month, for: selectedMonthStart)?.end.addingTimeInterval(-1)
        let sut = MainSummaryPeriodProvider(
            calendar: calendar,
            now: { now }
        )

        sut.updatePeriod(from: selectedMonthStart, to: expectedMonthEnd ?? now)
        let period = sut.currentMonthPeriod()

        XCTAssertEqual(period.from, selectedMonthStart)
        XCTAssertEqual(period.to, expectedMonthEnd)
    }

    func testCurrentMonthPeriodPreservesExplicitToDate() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: .zero) ?? .current

        let currentDate = calendar.date(from: DateComponents(
            timeZone: calendar.timeZone,
            year: 2025,
            month: 4,
            day: 20,
            hour: 8,
            minute: 30
        )) ?? .distantPast
        let selectedDate = calendar.date(from: DateComponents(
            timeZone: calendar.timeZone,
            year: 2025,
            month: 4,
            day: 3
        )) ?? .distantPast
        let explicitToDate = calendar.date(from: DateComponents(
            timeZone: calendar.timeZone,
            year: 2025,
            month: 4,
            day: 10,
            hour: 18,
            minute: 15
        )) ?? .distantPast
        let sut = MainSummaryPeriodProvider(
            calendar: calendar,
            now: { currentDate }
        )

        sut.updatePeriod(from: selectedDate, to: explicitToDate)
        let period = sut.currentMonthPeriod()

        XCTAssertEqual(period.from, selectedDate)
        XCTAssertEqual(period.to, explicitToDate)
    }
}

extension MainSummaryPeriodProviderTests {
    func testPickerStateUsesCurrentMonthRangeAndCurrentDayAsActiveToSelection() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: .zero) ?? .current

        let now = calendar.date(from: DateComponents(
            timeZone: calendar.timeZone,
            year: 2025,
            month: 4,
            day: 16,
            hour: 8,
            minute: 30
        )) ?? .distantPast
        let resolver = MainPeriodRangeResolver(calendar: calendar)

        let state = resolver.pickerState(
            for: resolver.defaultPeriod(for: now),
            now: now
        )

        XCTAssertEqual(
            state.fromDate,
            calendar.date(from: DateComponents(
                timeZone: calendar.timeZone,
                year: 2025,
                month: 4,
                day: 1
            ))
        )
        XCTAssertEqual(state.toDate, now)
        XCTAssertEqual(state.activeField, .to)
        XCTAssertEqual(state.selectedCalendarDate, now)
        XCTAssertEqual(
            state.visibleMonthDate,
            calendar.date(from: DateComponents(
                timeZone: calendar.timeZone,
                year: 2025,
                month: 4,
                day: 1
            ))
        )
        XCTAssertEqual(state.maximumDate, now)
        XCTAssertTrue(state.isApplyEnabled)
    }

    func testExplicitPeriodUsesEndOfPastDayForToDate() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: .zero) ?? .current

        let now = calendar.date(from: DateComponents(
            timeZone: calendar.timeZone,
            year: 2025,
            month: 4,
            day: 16,
            hour: 8,
            minute: 30
        )) ?? .distantPast
        let fromDate = calendar.date(from: DateComponents(
            timeZone: calendar.timeZone,
            year: 2025,
            month: 4,
            day: 3,
            hour: 19
        )) ?? .distantPast
        let toDate = calendar.date(from: DateComponents(
            timeZone: calendar.timeZone,
            year: 2025,
            month: 4,
            day: 10,
            hour: 14
        )) ?? .distantPast
        let expectedToDate = calendar.dateInterval(of: .day, for: toDate)?.end.addingTimeInterval(-1)
        let resolver = MainPeriodRangeResolver(calendar: calendar)

        let period = resolver.explicitPeriod(
            from: fromDate,
            to: toDate,
            now: now
        )

        XCTAssertEqual(
            period.from,
            calendar.date(from: DateComponents(
                timeZone: calendar.timeZone,
                year: 2025,
                month: 4,
                day: 3
            ))
        )
        XCTAssertEqual(period.to, expectedToDate)
    }

    func testExplicitPeriodUsesCurrentTimeWhenToDateIsToday() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: .zero) ?? .current

        let now = calendar.date(from: DateComponents(
            timeZone: calendar.timeZone,
            year: 2025,
            month: 4,
            day: 16,
            hour: 8,
            minute: 30
        )) ?? .distantPast
        let fromDate = calendar.date(from: DateComponents(
            timeZone: calendar.timeZone,
            year: 2025,
            month: 4,
            day: 3,
            hour: 19
        )) ?? .distantPast
        let todaySelection = calendar.date(from: DateComponents(
            timeZone: calendar.timeZone,
            year: 2025,
            month: 4,
            day: 16
        )) ?? .distantPast
        let resolver = MainPeriodRangeResolver(calendar: calendar)

        let period = resolver.explicitPeriod(
            from: fromDate,
            to: todaySelection,
            now: now
        )

        XCTAssertEqual(period.to, now)
    }
}
