import XCTest
@testable import Vault

final class MainValueFormatterTests: XCTestCase {
    func testExpenseTimeDateFormatWhenLocaleIsEnglishReturnsTwelveHourFormat() {
        let sut = MainValueFormatter()

        XCTAssertEqual(
            sut.expenseTimeDateFormat(for: Locale(identifier: "en_US")),
            "hh:mm a"
        )
    }

    func testExpenseTimeDateFormatWhenLocaleIsNotEnglishReturnsTwentyFourHourFormat() {
        let sut = MainValueFormatter()

        XCTAssertEqual(
            sut.expenseTimeDateFormat(for: Locale(identifier: "ru_RU")),
            "HH:mm"
        )
    }

    func testFormatExpenseTimeWhenLocaleIsEnglishReturnsTwelveHourTime() {
        let sut = MainValueFormatter(localeProvider: { Locale(identifier: "en_US") })
        let date = makeDate(hour: 17, minute: 5)

        XCTAssertEqual(
            sut.formatExpenseTime(date, now: date),
            "05:05 PM"
        )
    }

    func testFormatExpenseTimeWhenLocaleIsNotEnglishReturnsTwentyFourHourTime() {
        let sut = MainValueFormatter(localeProvider: { Locale(identifier: "ru_RU") })
        let date = makeDate(hour: 17, minute: 5)

        XCTAssertEqual(
            sut.formatExpenseTime(date, now: date),
            "17:05"
        )
    }
}

private extension MainValueFormatterTests {
    func makeDate(hour: Int, minute: Int) -> Date {
        Calendar(identifier: .gregorian).date(
            from: DateComponents(
                year: 2026,
                month: 4,
                day: 18,
                hour: hour,
                minute: minute
            )
        ) ?? Date(timeIntervalSince1970: 0)
    }
}
