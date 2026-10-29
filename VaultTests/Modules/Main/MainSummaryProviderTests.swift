import XCTest
@testable import Vylok

final class MainSummaryProviderTests: XCTestCase {
    private var summaryService: MainSummaryContractServicingMock!
    private var summaryPeriodProvider: MainSummaryPeriodProvidingMock!

    override func setUp() {
        super.setUp()
        summaryService = MainSummaryContractServicingMock()
        summaryPeriodProvider = MainSummaryPeriodProvidingMock()
        summaryPeriodProvider.currentMonthPeriodReturnValue = .init(
            from: Date(timeIntervalSince1970: 1_735_689_600),
            to: Date(timeIntervalSince1970: 1_735_700_000)
        )
    }

    override func tearDown() {
        summaryPeriodProvider = nil
        summaryService = nil
        super.tearDown()
    }
}

// MARK: - fetchSummary

extension MainSummaryProviderTests {
    func testFetchSummaryForwardsCurrentMonthRangeAndMapsResponse() async throws {
        // Arrange
        let sut = MainSummaryProvider(
            summaryService: summaryService,
            summaryPeriodProvider: summaryPeriodProvider
        )
        summaryService.getSummaryParametersReturnValue = SummaryResponseDTO(
            category: nil,
            total: 456.78,
            currency: "USD",
            byCategory: nil
        )

        // Act
        let summary = try await sut.fetchSummary()

        // Assert
        XCTAssertEqual(summary, MainSummaryModel(totalAmount: 456.78, currency: "USD", changePercent: .zero))
        XCTAssertEqual(
            summaryService.getSummaryParametersReceivedInvocations,
            [
                SummaryQueryParameters(
                    from: Date(timeIntervalSince1970: 1_735_689_600),
                    to: Date(timeIntervalSince1970: 1_735_700_000)
                )
            ]
        )
    }

    func testFetchSummaryWhenServiceFailsRethrowsError() async {
        // Arrange
        let sut = MainSummaryProvider(
            summaryService: summaryService,
            summaryPeriodProvider: summaryPeriodProvider
        )
        summaryService.getSummaryParametersThrowableError = TestError.any

        // Act
        let result = await Result { try await sut.fetchSummary() }

        // Assert
        XCTAssertEqual(result.failure as? TestError, .any)
    }
}
