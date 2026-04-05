import XCTest
@testable import Vault

final class MainSummaryProviderTests: XCTestCase {
    func testFetchSummaryForwardsCurrentMonthRangeAndMapsResponse() async throws {
        let from = Date(timeIntervalSince1970: 1_735_689_600)
        let to = Date(timeIntervalSince1970: 1_735_700_000)
        let service = MainSummaryServiceSpy(
            summaryResult: .success(
                .init(
                    category: nil,
                    total: 456.78,
                    currency: "USD",
                    byCategory: nil
                )
            )
        )
        let sut = MainSummaryProvider(
            summaryService: service,
            summaryPeriodProvider: MainSummaryPeriodProviderStub(
                period: .init(from: from, to: to)
            )
        )

        let summary = try await sut.fetchSummary()

        XCTAssertEqual(summary.totalAmount, 456.78)
        XCTAssertEqual(summary.currency, "USD")
        XCTAssertEqual(summary.changePercent, .zero)
        let requestedParameters = await service.requestedParameters()
        XCTAssertEqual(requestedParameters, [.init(from: from, to: to)])
    }
}

extension MainSummaryProviderTests {
    func testFetchSummaryWhenServiceFailsRethrowsError() async {
        let service = MainSummaryServiceSpy(summaryResult: .failure(StubError.any))
        let sut = MainSummaryProvider(
            summaryService: service,
            summaryPeriodProvider: MainSummaryPeriodProviderStub(
                period: .init(
                    from: Date(timeIntervalSince1970: 1),
                    to: Date(timeIntervalSince1970: 2)
                )
            )
        )

        do {
            _ = try await sut.fetchSummary()
            XCTFail("Expected throw")
        } catch {
            XCTAssertNotNil(error as? StubError)
        }
    }
}

private extension MainSummaryProviderTests {
    enum StubError: Error {
        case any
    }
}

private actor MainSummaryServiceSpy: MainSummaryContractServicing {
    private let summaryResult: Result<SummaryResponseDTO, Error>
    private var parametersHistory: [SummaryQueryParameters] = []

    init(summaryResult: Result<SummaryResponseDTO, Error>) {
        self.summaryResult = summaryResult
    }

    func getSummary(parameters: SummaryQueryParameters) async throws -> SummaryResponseDTO {
        parametersHistory.append(parameters)
        return try summaryResult.get()
    }

    func getSummaryByCategory(
        id: String,
        parameters: SummaryQueryParameters
    ) async throws -> SummaryResponseDTO {
        throw MainSummaryProviderTests.StubError.any
    }

    func requestedParameters() -> [SummaryQueryParameters] {
        parametersHistory
    }
}

private struct MainSummaryPeriodProviderStub: MainSummaryPeriodProviding {
    let period: MainSummaryPeriod

    func currentMonthPeriod() -> MainSummaryPeriod {
        period
    }
}
