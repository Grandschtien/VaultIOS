import XCTest
@testable import Vault

final class VaultWidgetSnapshotTimelineResolverTests: XCTestCase {
    private var calendar: Calendar!
    private var sut: VylokWidgetSnapshotTimelineResolver!

    override func setUp() {
        super.setUp()

        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: .zero)!
        sut = VylokWidgetSnapshotTimelineResolver(calendar: calendar)
    }

    override func tearDown() {
        sut = nil
        calendar = nil
        super.tearDown()
    }
}

extension VaultWidgetSnapshotTimelineResolverTests {
    func testResolveSnapshotKeepsFreshValuesWithinSameDay() {
        let snapshot = makeSnapshot(
            updatedAt: makeDate(year: 2026, month: 6, day: 23, hour: 10)
        )
        let resolvedSnapshot = sut.resolveSnapshot(
            snapshot,
            at: makeDate(year: 2026, month: 6, day: 23, hour: 22)
        )

        XCTAssertEqual(resolvedSnapshot, snapshot)
    }

    func testResolveSnapshotResetsTodayAfterMidnightAndKeepsMonth() {
        let snapshot = makeSnapshot(
            updatedAt: makeDate(year: 2026, month: 6, day: 23, hour: 21)
        )

        let resolvedSnapshot = sut.resolveSnapshot(
            snapshot,
            at: makeDate(year: 2026, month: 6, day: 24, hour: 0)
        )

        XCTAssertEqual(resolvedSnapshot?.todayAmount, .zero)
        XCTAssertEqual(resolvedSnapshot?.todayCurrency, "USD")
        XCTAssertEqual(resolvedSnapshot?.monthAmount, 450.2)
        XCTAssertEqual(resolvedSnapshot?.monthCurrency, "USD")
    }

    func testResolveSnapshotResetsTodayAndMonthAfterMonthBoundary() {
        let snapshot = makeSnapshot(
            updatedAt: makeDate(year: 2026, month: 6, day: 30, hour: 18)
        )

        let resolvedSnapshot = sut.resolveSnapshot(
            snapshot,
            at: makeDate(year: 2026, month: 7, day: 1, hour: 0)
        )

        XCTAssertEqual(resolvedSnapshot?.todayAmount, .zero)
        XCTAssertEqual(resolvedSnapshot?.monthAmount, .zero)
        XCTAssertEqual(resolvedSnapshot?.todayCurrency, "USD")
        XCTAssertEqual(resolvedSnapshot?.monthCurrency, "USD")
    }

    func testSignificantDatesReturnsMidnightAndNextMonthStartForFreshSameDaySnapshot() {
        let snapshot = makeSnapshot(
            updatedAt: makeDate(year: 2026, month: 6, day: 23, hour: 10)
        )

        let dates = sut.significantDates(
            for: snapshot,
            currentDate: makeDate(year: 2026, month: 6, day: 23, hour: 12)
        )

        XCTAssertEqual(
            dates,
            [
                makeDate(year: 2026, month: 6, day: 24, hour: 0),
                makeDate(year: 2026, month: 7, day: 1, hour: 0)
            ]
        )
    }
}

private extension VaultWidgetSnapshotTimelineResolverTests {
    func makeSnapshot(updatedAt: Date) -> VylokWidgetSnapshot {
        VylokWidgetSnapshot(
            entitlementState: .subscribed,
            todayAmount: 45.2,
            todayCurrency: "USD",
            monthAmount: 450.2,
            monthCurrency: "USD",
            updatedAt: updatedAt
        )
    }

    func makeDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int = 0
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
        )!
    }
}
