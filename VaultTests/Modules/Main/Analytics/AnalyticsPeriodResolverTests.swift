import XCTest
@testable import Vylok

final class AnalyticsPeriodResolverTests: XCTestCase {
    func testDefaultPeriodReturnsCurrentMonthPreset() {
        let resolution = makeSut().defaultPeriod()
        XCTAssertEqual(resolution.period, currentMonth)
        XCTAssertEqual(resolution.preset, .month)
    }

    func testResolveCurrentPeriodReturnsPresetRanges() {
        let sut = makeSut()
        XCTAssertEqual(sut.resolveCurrentPeriod(for: .day), .init(period: currentDay, preset: .day))
        XCTAssertEqual(sut.resolveCurrentPeriod(for: .week), .init(period: currentWeek, preset: .week))
        XCTAssertEqual(sut.resolveCurrentPeriod(for: .month), .init(period: currentMonth, preset: .month))
    }

    func testResolvePeriodRecognizesPresetRanges() {
        let sut = makeSut()
        XCTAssertEqual(sut.resolvePeriod(from: currentDay.from, to: currentDay.to), .init(period: currentDay, preset: .day))
        XCTAssertEqual(sut.resolvePeriod(from: previousDay.from, to: previousDay.to), .init(period: previousDay, preset: .day))
        XCTAssertEqual(sut.resolvePeriod(from: currentWeek.from, to: currentWeek.to), .init(period: currentWeek, preset: .week))
        XCTAssertEqual(sut.resolvePeriod(from: previousWeek.from, to: previousWeek.to), .init(period: previousWeek, preset: .week))
        XCTAssertEqual(sut.resolvePeriod(from: currentMonth.from, to: currentMonth.to), .init(period: currentMonth, preset: .month))
        XCTAssertEqual(sut.resolvePeriod(from: previousMonth.from, to: previousMonth.to), .init(period: previousMonth, preset: .month))
    }

    func testResolvePeriodReturnsCustomForNonPresetRanges() {
        let sut = makeSut()
        let partialMonth = MainSummaryPeriod(from: date(2026, 4, 2), to: now)
        let crossMonth = MainSummaryPeriod(from: previousMonth.from, to: now)
        XCTAssertEqual(sut.resolvePeriod(from: partialMonth.from, to: partialMonth.to), .init(period: partialMonth, preset: nil))
        XCTAssertEqual(sut.resolvePeriod(from: crossMonth.from, to: crossMonth.to), .init(period: crossMonth, preset: nil))
    }

    func testPreviousPeriodReturnsPreviousCalendarRange() {
        let sut = makeSut()
        XCTAssertEqual(sut.previousPeriod(for: .init(period: currentDay, preset: .day)), .init(period: previousDay, preset: .day))
        XCTAssertEqual(sut.previousPeriod(for: .init(period: currentWeek, preset: .week)), .init(period: previousWeek, preset: .week))
        XCTAssertEqual(sut.previousPeriod(for: .init(period: currentMonth, preset: .month)), .init(period: previousMonth, preset: .month))
    }
}

private extension AnalyticsPeriodResolverTests {
    var now: Date { date(2026, 4, 8, 14, 30) }

    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar
    }

    var weekCalendar: Calendar {
        var calendar = self.calendar
        calendar.firstWeekday = 2
        calendar.minimumDaysInFirstWeek = 4
        return calendar
    }

    var currentDay: MainSummaryPeriod { .init(from: calendar.startOfDay(for: now), to: now) }
    var previousDay: MainSummaryPeriod { .init(from: dayStart(-1), to: dayEnd(-1)) }
    var currentWeek: MainSummaryPeriod { .init(from: weekStart(0), to: now) }
    var previousWeek: MainSummaryPeriod { .init(from: weekStart(-1), to: weekEnd(-1)) }
    var currentMonth: MainSummaryPeriod { .init(from: monthStart(0), to: now) }
    var previousMonth: MainSummaryPeriod { .init(from: monthStart(-1), to: monthEnd(-1)) }

    func makeSut() -> AnalyticsPeriodResolver { AnalyticsPeriodResolver(calendar: calendar, now: { now }) }

    func dayStart(_ offset: Int) -> Date {
        calendar.startOfDay(for: weekCalendar.date(byAdding: .day, value: offset, to: now) ?? now)
    }

    func dayEnd(_ offset: Int) -> Date {
        let date = weekCalendar.date(byAdding: .day, value: offset, to: now) ?? now
        return calendar.dateInterval(of: .day, for: date)?.end.addingTimeInterval(-1) ?? now
    }

    func weekStart(_ offset: Int) -> Date {
        let date = weekCalendar.date(byAdding: .weekOfYear, value: offset, to: now) ?? now
        let start = weekCalendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
        return calendar.startOfDay(for: start)
    }

    func weekEnd(_ offset: Int) -> Date {
        let date = weekCalendar.date(byAdding: .weekOfYear, value: offset, to: now) ?? now
        return weekCalendar.dateInterval(of: .weekOfYear, for: date)?.end.addingTimeInterval(-1) ?? now
    }

    func monthStart(_ offset: Int) -> Date {
        let date = weekCalendar.date(byAdding: .month, value: offset, to: now) ?? now
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components).map { calendar.startOfDay(for: $0) } ?? date
    }

    func monthEnd(_ offset: Int) -> Date {
        let date = weekCalendar.date(byAdding: .month, value: offset, to: now) ?? now
        return calendar.dateInterval(of: .month, for: date)?.end.addingTimeInterval(-1) ?? now
    }

    func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0) -> Date {
        calendar.date(from: .init(timeZone: calendar.timeZone, year: year, month: month, day: day, hour: hour, minute: minute)) ?? .distantPast
    }
}
