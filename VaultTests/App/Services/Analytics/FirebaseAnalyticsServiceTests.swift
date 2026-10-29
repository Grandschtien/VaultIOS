import XCTest
import FirebaseAnalytics
@testable import Vylok

final class FirebaseAnalyticsServiceTests: XCTestCase {
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

// MARK: - send

extension FirebaseAnalyticsServiceTests {
    func testSendConfiguresClientAndForwardsEventNameAndParameters() async throws {
        // Arrange
        let sut = FirebaseAnalyticsService(client: client)

        // Act
        await sut.send(
            event: .screenOpen(.login),
            payload: AnalyticsPayload(rawPayload: ["title": "Coffee", "amount": 5])
        )

        // Assert
        let arguments = try XCTUnwrap(client.logEventParametersReceivedArguments)
        XCTAssertEqual(client.configureIfNeededCallsCount, 1)
        XCTAssertEqual(client.logEventParametersCallsCount, 1)
        XCTAssertEqual(arguments.name, "login_open")
        XCTAssertEqual(
            AnalyticsPayload(rawPayload: arguments.parameters ?? [:]),
            AnalyticsPayload(rawPayload: ["title": "Coffee", "amount": 5])
        )
    }

    func testSendReplacesAllDotsInEventNameWithUnderscores() async throws {
        // Arrange
        let sut = FirebaseAnalyticsService(client: client)

        // Act
        await sut.send(event: .tap(.manualTapPrimaryConfirm), payload: AnalyticsPayload(rawPayload: [:]))

        // Assert
        let arguments = try XCTUnwrap(client.logEventParametersReceivedArguments)
        XCTAssertEqual(arguments.name, "expense_manual_entry_primary_confirm_tap")
        XCTAssertNil(arguments.parameters)
    }

    func testSendMapsSubscriptionPurchaseSuccessToFirebasePurchaseEvent() async throws {
        // Arrange
        let sut = FirebaseAnalyticsService(client: client)

        // Act
        await sut.send(
            event: .subscriptionPurchaseSuccess,
            payload: AnalyticsPayload(
                rawPayload: [
                    "plan_id": "premium.monthly",
                    "plan_title": "Premium Monthly"
                ]
            )
        )

        // Assert
        let arguments = try XCTUnwrap(client.logEventParametersReceivedArguments)
        XCTAssertEqual(arguments.name, AnalyticsEventPurchase)
        XCTAssertEqual(
            AnalyticsPayload(rawPayload: arguments.parameters ?? [:]),
            AnalyticsPayload(
                rawPayload: [
                    "plan_id": "premium.monthly",
                    "plan_title": "Premium Monthly",
                    AnalyticsParameterItemID: "premium.monthly",
                    AnalyticsParameterItemName: "Premium Monthly"
                ]
            )
        )
    }

    func testSendMapsMainScreenOpenToFirebaseScreenViewEvent() async throws {
        // Arrange
        let sut = FirebaseAnalyticsService(client: client)

        // Act
        await sut.send(event: .screenOpen(.main), payload: AnalyticsPayload(rawPayload: [:]))

        // Assert
        let arguments = try XCTUnwrap(client.logEventParametersReceivedArguments)
        XCTAssertEqual(arguments.name, AnalyticsEventScreenView)
        XCTAssertEqual(
            AnalyticsPayload(rawPayload: arguments.parameters ?? [:]),
            AnalyticsPayload(
                rawPayload: [
                    AnalyticsParameterScreenName: AnalyticsScreen.main.rawValue,
                    AnalyticsParameterScreenClass: "MainViewController"
                ]
            )
        )
    }
}
