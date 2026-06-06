import XCTest
@testable import Vault

final class AnalyticsCoreManagerTests: XCTestCase {
    func testSendEventToFirebaseDispatchesMatchingService() async {
        let service = AnalyticsServiceSpy(provider: .firebase)
        let appLogService = AppLogServiceSpy()
        let sut = AnalyticsCoreManager(
            services: [service],
            userProfileStorageService: UserProfileStorageSpy(),
            appLogService: appLogService
        )

        sut.sendEvent(
            provider: AnalyticsProvider.firebase,
            event: AnalyticsEvent.screenOpen(.login),
            payload: ["name": "Coffee"]
        )
        await waitForCalls(expected: 1, service: service)
        await waitForLogEntries(expected: 1, service: appLogService)

        let calls = await service.calls()
        XCTAssertEqual(calls.count, 1)
        XCTAssertEqual(calls.first?.event, .screenOpen(.login))
        XCTAssertEqual(calls.first?.payload.values["name"], .string("Coffee"))
    }

    func testSendEventToAllDispatchesEveryRegisteredService() async {
        let firstService = AnalyticsServiceSpy(provider: .firebase)
        let secondService = AnalyticsServiceSpy(provider: .firebase)
        let appLogService = AppLogServiceSpy()
        let sut = AnalyticsCoreManager(
            services: [firstService, secondService],
            userProfileStorageService: UserProfileStorageSpy(),
            appLogService: appLogService
        )

        sut.sendEvent(
            provider: AnalyticsProvider.all,
            event: AnalyticsEvent.screenOpen(.profile),
            payload: [:]
        )
        await waitForCalls(expected: 1, service: firstService)
        await waitForCalls(expected: 1, service: secondService)
        await waitForLogEntries(expected: 1, service: appLogService)

        let firstCallsCount = await firstService.calls().count
        let secondCallsCount = await secondService.calls().count
        XCTAssertEqual(firstCallsCount, 1)
        XCTAssertEqual(secondCallsCount, 1)
    }

    func testSendEventAddsDefaultPayload() async {
        let service = AnalyticsServiceSpy(provider: .firebase)
        let appLogService = AppLogServiceSpy()
        let sut = AnalyticsCoreManager(
            services: [service],
            userProfileStorageService: UserProfileStorageSpy(
                storedProfile: .init(
                    userId: "user-1",
                    email: "mail@example.com",
                    name: "User",
                    currency: "USD",
                    language: "en"
                )
            ),
            appLogService: appLogService
        )

        sut.sendEvent(
            provider: AnalyticsProvider.firebase,
            event: AnalyticsEvent.screenOpen(.login),
            payload: ["name": "Coffee"]
        )
        await waitForCalls(expected: 1, service: service)
        await waitForLogEntries(expected: 1, service: appLogService)

        let call = await service.calls().first
        XCTAssertEqual(call?.payload.values["user_id"], .string("user-1"))
        XCTAssertEqual(call?.payload.values["name"], .string("Coffee"))
        XCTAssertNotNil(call?.payload.values["date_utc"])
    }

    func testSendEventMirrorsAnalyticsEventIntoLocalLogger() async {
        let service = AnalyticsServiceSpy(provider: .firebase)
        let appLogService = AppLogServiceSpy()
        let sut = AnalyticsCoreManager(
            services: [service],
            userProfileStorageService: UserProfileStorageSpy(),
            appLogService: appLogService
        )

        sut.sendEvent(
            provider: AnalyticsProvider.firebase,
            event: AnalyticsEvent.tap(.manualTapPrimaryConfirm),
            payload: ["step": 4]
        )
        await waitForCalls(expected: 1, service: service)
        await waitForLogEntries(expected: 1, service: appLogService)

        let logEntry = await appLogService.entries().first
        XCTAssertEqual(logEntry?.category, .analytics)
        XCTAssertEqual(logEntry?.name, AnalyticsEvent.tap(.manualTapPrimaryConfirm).name)
        XCTAssertEqual(logEntry?.source, "firebase")
        XCTAssertEqual(logEntry?.payload["step"], .int(4))
        XCTAssertEqual(logEntry?.session_id, appLogService.sessionID)
    }

    func testPayloadNormalizationKeepsSupportedValuesAndDropsUnsupportedValues() {
        let payload = AnalyticsPayload(
            rawPayload: [
                "string": "value",
                "int": 3,
                "double": 2.5,
                "bool": true,
                "nsString": NSString(string: "name"),
                "number": NSNumber(value: 8),
                "array": ["value", 3, NSNumber(value: true)],
                "unsupported": URL(string: "https://example.com") as Any
            ]
        )

        XCTAssertEqual(payload.values["string"], .string("value"))
        XCTAssertEqual(payload.values["int"], .int(3))
        XCTAssertEqual(payload.values["double"], .double(2.5))
        XCTAssertEqual(payload.values["bool"], .bool(true))
        XCTAssertEqual(payload.values["nsString"], .string("name"))
        XCTAssertEqual(payload.values["number"], .int(8))
        XCTAssertEqual(payload.values["array"], .array([.string("value"), .int(3), .bool(true)]))
        XCTAssertNil(payload.values["unsupported"])
    }
}

private extension AnalyticsCoreManagerTests {
    func waitForCalls(expected: Int, service: AnalyticsServiceSpy) async {
        while await service.calls().count < expected {
            await Task.yield()
        }
    }

    func waitForLogEntries(expected: Int, service: AppLogServiceSpy) async {
        while await service.entries().count < expected {
            await Task.yield()
        }
    }
}

private final class AnalyticsServiceSpy: AnalyticsServiceProtocol, @unchecked Sendable {
    struct Call: Equatable, Sendable {
        let event: AnalyticsEvent
        let payload: AnalyticsPayload
    }

    let provider: AnalyticsProvider
    private let delayNanoseconds: UInt64
    private let state = State()

    init(provider: AnalyticsProvider, delayNanoseconds: UInt64 = 0) {
        self.provider = provider
        self.delayNanoseconds = delayNanoseconds
    }

    func send(event: AnalyticsEvent, payload: AnalyticsPayload) async {
        if delayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: delayNanoseconds)
        }

        await state.append(.init(event: event, payload: payload))
    }

    func calls() async -> [Call] { await state.calls() }
}

private extension AnalyticsServiceSpy {
    actor State {
        private var storedCalls: [Call] = []

        func append(_ call: Call) { storedCalls.append(call) }
        func calls() -> [Call] { storedCalls }
    }
}

private final class UserProfileStorageSpy: UserProfileStorageServiceProtocol, @unchecked Sendable {
    private let storedProfile: UserProfileDefaults?

    init(storedProfile: UserProfileDefaults? = nil) {
        self.storedProfile = storedProfile
    }

    func saveProfile(_ profile: UserProfileDefaults) {}
    func loadProfile() -> UserProfileDefaults? { storedProfile }
    func clearProfile() {}
}
