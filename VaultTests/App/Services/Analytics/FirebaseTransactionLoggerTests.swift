import XCTest
import RevenueCat
@testable import Vylok

final class FirebaseTransactionLoggerTests: XCTestCase {
    func testTrackTransactionIfNeededSkipsNilTransaction() async {
        let spy = FirebaseTransactionLoggerSpy()
        let sut = FirebaseTransactionLogger(
            configureIfNeededHandler: {
                await spy.recordConfigure()
            },
            transactionLogActionResolver: { _ in
                { await spy.recordLog() }
            }
        )

        await sut.trackTransactionIfNeeded(nil)

        let configureCallsCount = await spy.configureCallsCount()
        let logCallsCount = await spy.logCallsCount()
        XCTAssertEqual(configureCallsCount, 0)
        XCTAssertEqual(logCallsCount, 0)
    }

    func testTrackTransactionIfNeededSkipsTransactionWithoutResolvedAction() async {
        let spy = FirebaseTransactionLoggerSpy()
        let sut = FirebaseTransactionLogger(
            configureIfNeededHandler: {
                await spy.recordConfigure()
            },
            transactionLogActionResolver: { _ in nil }
        )

        await sut.trackTransactionIfNeeded(
            StoreTransaction(
                productIdentifier: "premium.monthly",
                purchaseDate: Date(timeIntervalSince1970: 10),
                transactionIdentifier: "transaction-1"
            )
        )

        let configureCallsCount = await spy.configureCallsCount()
        let logCallsCount = await spy.logCallsCount()
        XCTAssertEqual(configureCallsCount, 0)
        XCTAssertEqual(logCallsCount, 0)
    }

    func testTrackTransactionIfNeededConfiguresClientAndRunsResolvedAction() async {
        let spy = FirebaseTransactionLoggerSpy()
        let sut = FirebaseTransactionLogger(
            configureIfNeededHandler: {
                await spy.recordConfigure()
            },
            transactionLogActionResolver: { _ in
                { await spy.recordLog() }
            }
        )

        await sut.trackTransactionIfNeeded(
            StoreTransaction(
                productIdentifier: "premium.monthly",
                purchaseDate: Date(timeIntervalSince1970: 10),
                transactionIdentifier: "transaction-1"
            )
        )

        let configureCallsCount = await spy.configureCallsCount()
        let logCallsCount = await spy.logCallsCount()
        XCTAssertEqual(configureCallsCount, 1)
        XCTAssertEqual(logCallsCount, 1)
    }
}

private actor FirebaseTransactionLoggerSpy {
    private var configureCallCount = 0
    private var logCallCount = 0

    func recordConfigure() {
        configureCallCount += 1
    }

    func recordLog() {
        logCallCount += 1
    }

    func configureCallsCount() -> Int {
        configureCallCount
    }

    func logCallsCount() -> Int {
        logCallCount
    }
}
