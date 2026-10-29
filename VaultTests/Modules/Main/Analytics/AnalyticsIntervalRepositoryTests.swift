import XCTest
@testable import Vylok

final class AnalyticsIntervalRepositoryTests: XCTestCase {
    private var calendar: Calendar!
    private var sut: AnalyticsIntervalRepository!

    override func setUp() {
        super.setUp()
        calendar = makeCalendar()
        sut = AnalyticsIntervalRepository(calendar: calendar)
    }

    override func tearDown() {
        sut = nil
        calendar = nil
        super.tearDown()
    }
}

// MARK: - cachedData

extension AnalyticsIntervalRepositoryTests {
    func testCachedDataWhenNothingSavedReturnsNil() async {
        // Arrange
        let resolution = makeResolution(
            from: date(year: 2026, month: 7, day: 4, hour: 0),
            to: date(year: 2026, month: 7, day: 4, hour: 9),
            preset: .day
        )

        // Act
        let result = await sut.cachedData(for: resolution)

        // Assert
        XCTAssertNil(result)
    }

    func testCachedDataWhenPresetMatchesSameDayOfPeriodEndReturnsSavedData() async {
        // Arrange
        let cachedResolution = makeResolution(
            from: date(year: 2026, month: 7, day: 1, hour: 0),
            to: date(year: 2026, month: 7, day: 4, hour: 9),
            preset: .month
        )
        let requestedResolution = makeResolution(
            from: date(year: 2026, month: 7, day: 1, hour: 0),
            to: date(year: 2026, month: 7, day: 4, hour: 18),
            preset: .month
        )
        await sut.save(data: makeData(totalAmount: 120), for: cachedResolution)

        // Act
        let result = await sut.cachedData(for: requestedResolution)

        // Assert
        XCTAssertEqual(result, makeData(totalAmount: 120))
    }

    func testCachedDataWhenCustomResolutionMatchesExactlyReturnsSavedData() async {
        // Arrange
        let resolution = makeResolution(
            from: date(year: 2026, month: 7, day: 2, hour: 0),
            to: date(year: 2026, month: 7, day: 5, hour: 9),
            preset: nil
        )
        await sut.save(data: makeData(totalAmount: 80), for: resolution)

        // Act
        let result = await sut.cachedData(for: resolution)

        // Assert
        XCTAssertEqual(result, makeData(totalAmount: 80))
    }

    func testCachedDataWhenCustomResolutionEndDiffersReturnsNil() async {
        // Arrange
        await sut.save(
            data: makeData(totalAmount: 80),
            for: makeResolution(
                from: date(year: 2026, month: 7, day: 2, hour: 0),
                to: date(year: 2026, month: 7, day: 5, hour: 9),
                preset: nil
            )
        )
        let requestedResolution = makeResolution(
            from: date(year: 2026, month: 7, day: 2, hour: 0),
            to: date(year: 2026, month: 7, day: 5, hour: 18),
            preset: nil
        )

        // Act
        let result = await sut.cachedData(for: requestedResolution)

        // Assert
        XCTAssertNil(result)
    }
}

// MARK: - invalidateIntersecting

extension AnalyticsIntervalRepositoryTests {
    func testInvalidateIntersectingRemovesOnlyIntervalsContainingDate() async {
        // Arrange
        let presetResolution = makeResolution(
            from: date(year: 2026, month: 7, day: 4, hour: 0),
            to: date(year: 2026, month: 7, day: 4, hour: 9),
            preset: .day
        )
        let shortCustomResolution = makeResolution(
            from: date(year: 2026, month: 7, day: 4, hour: 0),
            to: date(year: 2026, month: 7, day: 4, hour: 9),
            preset: nil
        )
        let longCustomResolution = makeResolution(
            from: date(year: 2026, month: 7, day: 4, hour: 0),
            to: date(year: 2026, month: 7, day: 4, hour: 18),
            preset: nil
        )
        await sut.save(data: makeData(totalAmount: 10), for: presetResolution)
        await sut.save(data: makeData(totalAmount: 20), for: shortCustomResolution)
        await sut.save(data: makeData(totalAmount: 30), for: longCustomResolution)

        // Act
        await sut.invalidateIntersecting(with: [date(year: 2026, month: 7, day: 4, hour: 14)])

        // Assert
        let presetData = await sut.cachedData(for: presetResolution)
        let shortCustomData = await sut.cachedData(for: shortCustomResolution)
        let longCustomData = await sut.cachedData(for: longCustomResolution)
        XCTAssertNil(presetData)
        XCTAssertEqual(shortCustomData, makeData(totalAmount: 20))
        XCTAssertNil(longCustomData)
    }
}

// MARK: - clear

extension AnalyticsIntervalRepositoryTests {
    func testClearRemovesAllSavedIntervals() async {
        // Arrange
        let resolution = makeResolution(
            from: date(year: 2026, month: 7, day: 1, hour: 0),
            to: date(year: 2026, month: 7, day: 3, hour: 10),
            preset: .week
        )
        await sut.save(data: makeData(totalAmount: 55), for: resolution)

        // Act
        await sut.clear()

        // Assert
        let result = await sut.cachedData(for: resolution)
        XCTAssertNil(result)
    }
}

private extension AnalyticsIntervalRepositoryTests {
    func makeResolution(
        from: Date,
        to: Date,
        preset: AnalyticsPeriodPreset?
    ) -> AnalyticsPeriodResolution {
        AnalyticsPeriodResolution(
            period: MainSummaryPeriod(
                from: from,
                to: to
            ),
            preset: preset
        )
    }

    func makeData(totalAmount: Double) -> AnalyticsDataModel {
        AnalyticsDataModel(
            monthStart: date(year: 2026, month: 7, day: 1, hour: 0),
            totalAmount: totalAmount,
            currency: "USD",
            categories: [
                .init(
                    id: "food",
                    name: "Food",
                    icon: "fork.knife",
                    colorValue: "light_orange",
                    amount: totalAmount,
                    currency: "USD",
                    share: 1,
                    isInteractive: true
                )
            ]
        )
    }

    func makeCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar
    }

    func date(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int = 0
    ) -> Date {
        calendar.date(
            from: DateComponents(
                calendar: calendar,
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
