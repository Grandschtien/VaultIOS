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
}
