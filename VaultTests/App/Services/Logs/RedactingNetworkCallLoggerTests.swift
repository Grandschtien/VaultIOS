import XCTest
import NetworkClient
@testable import Vylok

final class RedactingNetworkCallLoggerTests: XCTestCase {
    func testLogRequestRedactsSecretsAndPreservesRequestID() async {
        let appLogService = AppLogServiceSpy()
        let sut = RedactingNetworkCallLogger(appLogService: appLogService)

        sut.logRequest(
            NetworkRequestLogEntry(
                requestID: "request-1",
                timestamp: .init(timeIntervalSince1970: 1_775_001_600),
                method: "POST",
                url: "https://vault.example/api?token=secret&name=coffee",
                headers: ["Authorization": "Bearer secret"],
                body: #"{"refreshToken":"secret","name":"coffee"}"#
            )
        )
        await waitForEntries(expected: 1, service: appLogService)

        let entry = await appLogService.entries().first
        XCTAssertEqual(entry?.request_id, "request-1")
        XCTAssertEqual(entry?.category, .network)
        XCTAssertEqual(entry?.name, "request")
        XCTAssertEqual(entry?.payload["url"], .string("https://vault.example/api?token=%3Credacted%3E&name=coffee"))
        XCTAssertEqual(entry?.payload["headers"], .array([.string("Authorization: <redacted>")]))
        guard case let .string(body) = entry?.payload["body"] else {
            return XCTFail("Expected sanitized request body")
        }
        XCTAssertTrue(body.contains(#""refreshToken":"<redacted>""#))
        XCTAssertTrue(body.contains(#""name":"coffee""#))
    }

    func testLogResponseWritesSanitizedStatusDurationAndError() async {
        let appLogService = AppLogServiceSpy()
        let sut = RedactingNetworkCallLogger(appLogService: appLogService)

        sut.logResponse(
            NetworkResponseLogEntry(
                requestID: "request-2",
                timestamp: .init(timeIntervalSince1970: 1_775_001_600),
                method: "GET",
                url: "https://vault.example/profile",
                statusCode: 401,
                durationMs: 245,
                body: "access_token=secret&name=coffee",
                errorDescription: "token=secret"
            )
        )
        await waitForEntries(expected: 1, service: appLogService)

        let entry = await appLogService.entries().first
        XCTAssertEqual(entry?.request_id, "request-2")
        XCTAssertEqual(entry?.name, "response")
        XCTAssertEqual(entry?.payload["status_code"], .int(401))
        XCTAssertEqual(entry?.payload["duration_ms"], .int(245))
        XCTAssertEqual(entry?.payload["body"], .string("access_token=<redacted>&name=coffee"))
        XCTAssertEqual(entry?.payload["error_description"], .string("token=<redacted>"))
    }
}

private extension RedactingNetworkCallLoggerTests {
    func waitForEntries(expected: Int, service: AppLogServiceSpy) async {
        while await service.entries().count < expected {
            await Task.yield()
        }
    }
}
