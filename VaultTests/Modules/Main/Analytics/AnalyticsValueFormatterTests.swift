import XCTest
@testable import Vylok

final class AnalyticsValueFormatterTests: XCTestCase {
    func testFormatMonthWhenLocaleIsRussianReturnsStandaloneMonthWithYear() {
        let sut = AnalyticsValueFormatter(
            localeProvider: { Locale(identifier: "ru_RU") }
        )

        XCTAssertEqual(
            sut.formatMonth(makeDate(year: 2026, month: 6, day: 1)),
            "Июнь 2026"
        )
    }

    func testFormatMonthWhenLocaleIsEnglishReturnsMonthWithYear() {
        let sut = AnalyticsValueFormatter(
            localeProvider: { Locale(identifier: "en_US") }
        )

        XCTAssertEqual(
            sut.formatMonth(makeDate(year: 2026, month: 6, day: 1)),
            "June 2026"
        )
    }
}

private extension AnalyticsValueFormatterTests {
    func makeDate(
        year: Int,
        month: Int,
        day: Int
    ) -> Date {
        Calendar(identifier: .gregorian).date(
            from: DateComponents(
                year: year,
                month: month,
                day: day
            )
        ) ?? Date(timeIntervalSince1970: 0)
    }
}
