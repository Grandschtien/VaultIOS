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

extension AnalyticsIntervalRepositoryTests {
    func testNewInstanceStartsEmpty() async {
        XCTAssertNil(
            await sut.cachedData(
                for: makeResolution(
                    from: date(year: 2026, month: 7, day: 4, hour: 0),
                    to: date(year: 2026, month: 7, day: 4, hour: 9),
                    preset: .day
                )
            )
        )
    }

    func testSaveAndReadPresetResolutionUsingSameCalendarDayOfPeriodEnd() async {
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
        let data = makeData(totalAmount: 120)

        await sut.save(data: data, for: cachedResolution)

        XCTAssertEqual(await sut.cachedData(for: requestedResolution), data)
    }

    func testCustomResolutionRequiresExactFromAndToMatch() async {
        let cachedResolution = makeResolution(
            from: date(year: 2026, month: 7, day: 2, hour: 0),
            to: date(year: 2026, month: 7, day: 5, hour: 9),
            preset: nil
        )
        let exactResolution = makeResolution(
            from: date(year: 2026, month: 7, day: 2, hour: 0),
            to: date(year: 2026, month: 7, day: 5, hour: 9),
            preset: nil
        )
        let differentEndResolution = makeResolution(
            from: date(year: 2026, month: 7, day: 2, hour: 0),
            to: date(year: 2026, month: 7, day: 5, hour: 18),
            preset: nil
        )
        let data = makeData(totalAmount: 80)

        await sut.save(data: data, for: cachedResolution)

        XCTAssertEqual(await sut.cachedData(for: exactResolution), data)
        XCTAssertNil(await sut.cachedData(for: differentEndResolution))
    }

    func testInvalidateIntersectingRemovesOnlyMatchingIntervals() async {
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

        await sut.invalidateIntersecting(
            with: [date(year: 2026, month: 7, day: 4, hour: 14)]
        )

        XCTAssertNil(await sut.cachedData(for: presetResolution))
        XCTAssertEqual(
            await sut.cachedData(for: shortCustomResolution)?.totalAmount,
            20
        )
        XCTAssertNil(await sut.cachedData(for: longCustomResolution))
    }

    func testClearRemovesAllSavedIntervals() async {
        await sut.save(
            data: makeData(totalAmount: 55),
            for: makeResolution(
                from: date(year: 2026, month: 7, day: 1, hour: 0),
                to: date(year: 2026, month: 7, day: 3, hour: 10),
                preset: .week
            )
        )

        await sut.clear()

        XCTAssertNil(
            await sut.cachedData(
                for: makeResolution(
                    from: date(year: 2026, month: 7, day: 1, hour: 0),
                    to: date(year: 2026, month: 7, day: 3, hour: 10),
                    preset: .week
                )
            )
        )
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
