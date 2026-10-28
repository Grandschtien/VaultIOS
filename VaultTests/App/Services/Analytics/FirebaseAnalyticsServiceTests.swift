import XCTest
import FirebaseAnalytics
@testable import Vylok

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
        XCTAssertEqual(loggedEventName, "login_open")
        XCTAssertEqual(loggedPayload, AnalyticsPayload(rawPayload: ["title": "Coffee", "amount": 5]))
    }

    func testSendReplacesAllDotsInEventNameWithUnderscores() async {
        let spy = FirebaseAnalyticsServiceSpy()
        let sut = FirebaseAnalyticsService(
            configureIfNeededHandler: {},
            logEventHandler: { name, parameters in
                await spy.recordLog(name: name, parameters: parameters)
            }
        )

        await sut.send(event: .tap(.manualTapPrimaryConfirm), payload: AnalyticsPayload(rawPayload: [:]))

        let loggedEventName = await spy.loggedEventName()
        XCTAssertEqual(loggedEventName, "expense_manual_entry_primary_confirm_tap")
    }

    func testSendMapsSubscriptionPurchaseSuccessToFirebasePurchaseEvent() async {
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
            event: .subscriptionPurchaseSuccess,
            payload: AnalyticsPayload(
                rawPayload: [
                    "plan_id": "premium.monthly",
                    "plan_title": "Premium Monthly"
                ]
            )
        )

        let loggedEventName = await spy.loggedEventName()
        let loggedPayload = await spy.loggedPayload()

        XCTAssertEqual(loggedEventName, AnalyticsEventPurchase)
        XCTAssertEqual(loggedPayload?.values["plan_id"], .string("premium.monthly"))
        XCTAssertEqual(loggedPayload?.values["plan_title"], .string("Premium Monthly"))
        XCTAssertEqual(loggedPayload?.values[AnalyticsParameterItemID], .string("premium.monthly"))
        XCTAssertEqual(loggedPayload?.values[AnalyticsParameterItemName], .string("Premium Monthly"))
    }

    func testSendMapsMainScreenOpenToFirebaseScreenViewEvent() async {
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
            event: .screenOpen(.main),
            payload: AnalyticsPayload(rawPayload: [:])
        )

        let loggedEventName = await spy.loggedEventName()
        let loggedPayload = await spy.loggedPayload()

        XCTAssertEqual(loggedEventName, AnalyticsEventScreenView)
        XCTAssertEqual(loggedPayload?.values[AnalyticsParameterScreenName], .string(AnalyticsScreen.main.rawValue))
        XCTAssertEqual(loggedPayload?.values[AnalyticsParameterScreenClass], .string("MainViewController"))
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
