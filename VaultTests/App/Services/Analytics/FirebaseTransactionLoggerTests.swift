import XCTest
import RevenueCat
@testable import Vylok

final class FirebaseTransactionLoggerTests: XCTestCase {
    private var client: FirebaseAnalyticsClientProtocolMock!

    override func setUp() {
        super.setUp()
        client = FirebaseAnalyticsClientProtocolMock()
    }

    override func tearDown() {
        client = nil
        super.tearDown()
    }
}

// MARK: - trackTransactionIfNeeded

extension FirebaseTransactionLoggerTests {
    func testTrackTransactionIfNeededWhenTransactionIsNilSkipsLogging() async {
        // Arrange
        let sut = FirebaseTransactionLogger(client: client)

        // Act
        await sut.trackTransactionIfNeeded(nil)

        // Assert
        XCTAssertFalse(client.logTransactionCalled)
    }

    func testTrackTransactionIfNeededLogsTransaction() async {
        // Arrange
        let sut = FirebaseTransactionLogger(client: client)
        let transaction = StoreTransaction(
            productIdentifier: "premium.monthly",
            purchaseDate: Date(timeIntervalSince1970: 10),
            transactionIdentifier: "transaction-1"
        )

        // Act
        await sut.trackTransactionIfNeeded(transaction)

        // Assert
        XCTAssertEqual(client.logTransactionReceivedInvocations.map(\.transactionIdentifier), ["transaction-1"])
    }
}
