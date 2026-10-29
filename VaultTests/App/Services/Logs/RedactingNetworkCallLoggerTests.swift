import XCTest
import NetworkClient
@testable import Vylok

final class RedactingNetworkCallLoggerTests: XCTestCase {
    private var appLogService: AppLogServiceProtocolMock!

    override func setUp() {
        super.setUp()
        appLogService = AppLogServiceProtocolMock()
    }

    override func tearDown() {
        appLogService = nil
        super.tearDown()
    }
}

// MARK: - logRequest

extension RedactingNetworkCallLoggerTests {
    func testLogRequestRedactsSecretsAndPreservesRequestID() throws {
        // Arrange
        let sut = RedactingNetworkCallLogger(appLogService: appLogService)
        let entry = NetworkRequestLogEntry(
            requestID: "request-1",
            timestamp: .init(timeIntervalSince1970: 1_775_001_600),
            method: "POST",
            url: "https://vault.example/api?token=secret&name=coffee",
            headers: ["Authorization": "Bearer secret"],
            body: #"{"refreshToken":"secret","name":"coffee"}"#
        )

        // Act
        sut.logRequest(entry)

        // Assert
        let arguments = try XCTUnwrap(
            appLogService.logCategoryNameSourcePayloadRequestIDSubscriptionAttemptIDReceivedArguments
        )
        let body = try XCTUnwrap(arguments.payload["body"] as? String)
        XCTAssertEqual(appLogService.logCategoryNameSourcePayloadRequestIDSubscriptionAttemptIDCallsCount, 1)
        XCTAssertEqual(arguments.category, .network)
        XCTAssertEqual(arguments.name, "request")
        XCTAssertEqual(arguments.source, "NetworkClient")
        XCTAssertEqual(arguments.requestID, "request-1")
        XCTAssertNil(arguments.subscriptionAttemptID)
        XCTAssertEqual(arguments.payload["method"] as? String, "POST")
        XCTAssertEqual(
            arguments.payload["url"] as? String,
            "https://vault.example/api?token=%3Credacted%3E&name=coffee"
        )
        XCTAssertEqual(arguments.payload["headers"] as? [String], ["Authorization: <redacted>"])
        XCTAssertTrue(body.contains(#""refreshToken":"<redacted>""#))
        XCTAssertTrue(body.contains(#""name":"coffee""#))
    }
}

// MARK: - logResponse

extension RedactingNetworkCallLoggerTests {
    func testLogResponseWritesSanitizedStatusDurationAndError() throws {
        // Arrange
        let sut = RedactingNetworkCallLogger(appLogService: appLogService)
        let entry = NetworkResponseLogEntry(
            requestID: "request-2",
            timestamp: .init(timeIntervalSince1970: 1_775_001_600),
            method: "GET",
            url: "https://vault.example/profile",
            statusCode: 401,
            durationMs: 245,
            body: "access_token=secret&name=coffee",
            errorDescription: "token=secret"
        )

        // Act
        sut.logResponse(entry)

        // Assert
        let arguments = try XCTUnwrap(
            appLogService.logCategoryNameSourcePayloadRequestIDSubscriptionAttemptIDReceivedArguments
        )
        XCTAssertEqual(appLogService.logCategoryNameSourcePayloadRequestIDSubscriptionAttemptIDCallsCount, 1)
        XCTAssertEqual(arguments.category, .network)
        XCTAssertEqual(arguments.name, "response")
        XCTAssertEqual(arguments.requestID, "request-2")
        XCTAssertEqual(arguments.payload["status_code"] as? Int, 401)
        XCTAssertEqual(arguments.payload["duration_ms"] as? Int, 245)
        XCTAssertEqual(arguments.payload["body"] as? String, "access_token=<redacted>&name=coffee")
        XCTAssertEqual(arguments.payload["error_description"] as? String, "token=<redacted>")
    }
}
