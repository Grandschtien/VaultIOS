import XCTest
@testable import Vault

final class FirebaseAnalyticsServiceTests: XCTestCase {
    func testSendConfiguresClientAndForwardsEventNameAndParameters() async {
        let spy = FirebaseAnalyticsServiceSpy()
        let sut = FirebaseAnalyticsService(
            configureIfNeededHandler: {
                await spy.recordConfigure()
            },
            logEventHandler: { name, parameters in
                await spy.recordLog(name: name, parameters: parameters)
            }
        )

        await sut.send(
            event: .screenOpen(.login),
            payload: AnalyticsPayload(
                rawPayload: ["title": "Coffee", "amount": 5]
            )
        )

        let configureCallsCount = await spy.configureCallsCount()
        let loggedEventName = await spy.loggedEventName()
        let loggedPayload = await spy.loggedPayload()
        XCTAssertEqual(configureCallsCount, 1)
        XCTAssertEqual(loggedEventName, AnalyticsEvent.screenOpen(.login).name)
        XCTAssertEqual(loggedPayload, AnalyticsPayload(rawPayload: ["title": "Coffee", "amount": 5]))
    }
}

private actor FirebaseAnalyticsServiceSpy {
    private let state = State()

    func recordConfigure() async {
        await state.recordConfigure()
    }

    func recordLog(name: String, parameters: [String: Any]?) async {
        await state.recordLog(
            name: name,
            payload: AnalyticsPayload(rawPayload: parameters ?? [:])
        )
    }

    func configureCallsCount() async -> Int { await state.configureCallsCount() }
    func loggedEventName() async -> String? { await state.loggedEventName() }
    func loggedPayload() async -> AnalyticsPayload? { await state.loggedPayload() }
}

private extension FirebaseAnalyticsServiceSpy {
    actor State {
        private var configureCallCount = 0
        private var storedEventName: String?
        private var storedPayload: AnalyticsPayload?

        func recordConfigure() { configureCallCount += 1 }
        func recordLog(name: String, payload: AnalyticsPayload) { storedEventName = name; storedPayload = payload }
        func configureCallsCount() -> Int { configureCallCount }
        func loggedEventName() -> String? { storedEventName }
        func loggedPayload() -> AnalyticsPayload? { storedPayload }
    }
}
