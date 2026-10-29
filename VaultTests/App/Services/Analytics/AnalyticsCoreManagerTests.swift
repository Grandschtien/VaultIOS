import XCTest
@testable import Vylok

final class AnalyticsCoreManagerTests: XCTestCase {
    private var firstService: AnalyticsServiceProtocolMock!
    private var secondService: AnalyticsServiceProtocolMock!
    private var userProfileStorageService: UserProfileStorageServiceProtocolMock!
    private var appLogService: AppLogServiceProtocolMock!

    override func setUp() {
        super.setUp()
        firstService = AnalyticsServiceProtocolMock()
        firstService.provider = .firebase
        secondService = AnalyticsServiceProtocolMock()
        secondService.provider = .firebase
        userProfileStorageService = UserProfileStorageServiceProtocolMock()
        appLogService = AppLogServiceProtocolMock()
    }

    override func tearDown() {
        appLogService = nil
        userProfileStorageService = nil
        secondService = nil
        firstService = nil
        super.tearDown()
    }
}

// MARK: - sendEvent

extension AnalyticsCoreManagerTests {
    func testSendEventWhenProviderIsFirebaseDispatchesEventToMatchingService() async throws {
        // Arrange
        let sut = AnalyticsCoreManager(
            services: [firstService],
            userProfileStorageService: userProfileStorageService,
            appLogService: appLogService
        )
        let eventSent = expectation(description: "Event sent")
        firstService.sendEventPayloadClosure = { _, _ in
            eventSent.fulfill()
        }

        // Act
        sut.sendEvent(
            provider: .firebase,
            event: .screenOpen(.login),
            payload: ["name": "Coffee"]
        )
        await fulfillment(of: [eventSent], timeout: 1)

        // Assert
        let arguments = try XCTUnwrap(firstService.sendEventPayloadReceivedArguments)
        XCTAssertEqual(firstService.sendEventPayloadCallsCount, 1)
        XCTAssertEqual(arguments.event, .screenOpen(.login))
        XCTAssertEqual(arguments.payload.values["name"], .string("Coffee"))
    }

    func testSendEventWhenProviderIsAllDispatchesEveryRegisteredService() async {
        // Arrange
        let sut = AnalyticsCoreManager(
            services: [firstService, secondService],
            userProfileStorageService: userProfileStorageService,
            appLogService: appLogService
        )
        let firstEventSent = expectation(description: "First service received event")
        let secondEventSent = expectation(description: "Second service received event")
        firstService.sendEventPayloadClosure = { _, _ in
            firstEventSent.fulfill()
        }
        secondService.sendEventPayloadClosure = { _, _ in
            secondEventSent.fulfill()
        }

        // Act
        sut.sendEvent(
            provider: .all,
            event: .screenOpen(.profile),
            payload: [:]
        )
        await fulfillment(of: [firstEventSent, secondEventSent], timeout: 1)

        // Assert
        XCTAssertEqual(firstService.sendEventPayloadCallsCount, 1)
        XCTAssertEqual(secondService.sendEventPayloadCallsCount, 1)
    }

    func testSendEventAddsDefaultPayload() async throws {
        // Arrange
        let sut = AnalyticsCoreManager(
            services: [firstService],
            userProfileStorageService: userProfileStorageService,
            appLogService: appLogService
        )
        userProfileStorageService.loadProfileReturnValue = UserProfileDefaults(
            userId: "user-1",
            email: "mail@example.com",
            name: "User",
            currency: "USD",
            language: "en"
        )
        let eventSent = expectation(description: "Event sent")
        firstService.sendEventPayloadClosure = { _, _ in
            eventSent.fulfill()
        }

        // Act
        sut.sendEvent(
            provider: .firebase,
            event: .screenOpen(.login),
            payload: ["name": "Coffee"]
        )
        await fulfillment(of: [eventSent], timeout: 1)

        // Assert
        let payload = try XCTUnwrap(firstService.sendEventPayloadReceivedArguments?.payload)
        XCTAssertEqual(payload.values["user_id"], .string("user-1"))
        XCTAssertEqual(payload.values["name"], .string("Coffee"))
        XCTAssertNotNil(payload.values["date_utc"])
    }

    func testSendEventMirrorsAnalyticsEventIntoLocalLogger() throws {
        // Arrange
        let sut = AnalyticsCoreManager(
            services: [firstService],
            userProfileStorageService: userProfileStorageService,
            appLogService: appLogService
        )

        // Act
        sut.sendEvent(
            provider: .firebase,
            event: .tap(.manualTapPrimaryConfirm),
            payload: ["step": 4]
        )

        // Assert
        let arguments = try XCTUnwrap(
            appLogService.logCategoryNameSourcePayloadRequestIDSubscriptionAttemptIDReceivedArguments
        )
        XCTAssertEqual(appLogService.logCategoryNameSourcePayloadRequestIDSubscriptionAttemptIDCallsCount, 1)
        XCTAssertEqual(arguments.category, .analytics)
        XCTAssertEqual(arguments.name, AnalyticsEvent.tap(.manualTapPrimaryConfirm).name)
        XCTAssertEqual(arguments.source, "firebase")
        XCTAssertEqual(arguments.payload["step"] as? Int, 4)
    }
}

// MARK: - AnalyticsPayload

extension AnalyticsCoreManagerTests {
    func testPayloadNormalizationKeepsSupportedValuesAndDropsUnsupportedValues() {
        // Arrange
        let rawPayload: [String: Any] = [
            "string": "value",
            "int": 3,
            "double": 2.5,
            "bool": true,
            "nsString": NSString(string: "name"),
            "number": NSNumber(value: 8),
            "array": ["value", 3, NSNumber(value: true)],
            "unsupported": URL(string: "https://example.com") as Any
        ]

        // Act
        let payload = AnalyticsPayload(rawPayload: rawPayload)

        // Assert
        XCTAssertEqual(
            payload.values,
            [
                "string": .string("value"),
                "int": .int(3),
                "double": .double(2.5),
                "bool": .bool(true),
                "nsString": .string("name"),
                "number": .int(8),
                "array": .array([.string("value"), .int(3), .bool(true)])
            ]
        )
    }
}
