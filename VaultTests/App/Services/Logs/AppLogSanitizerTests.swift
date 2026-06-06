import XCTest
@testable import Vault

final class AppLogSanitizerTests: XCTestCase {
    func testSanitizeURLRedactsSensitiveQueryItems() {
        let sut = AppLogSanitizer()

        let result = sut.sanitizeURL(
            "https://vault.example/api?access_token=secret&name=coffee"
        )

        XCTAssertEqual(
            result,
            "https://vault.example/api?access_token=%3Credacted%3E&name=coffee"
        )
    }

    func testSanitizeBodyRedactsNestedJSONSecrets() {
        let sut = AppLogSanitizer()

        let result = sut.sanitizeBody(
            #"{"token":"secret","nested":{"refreshToken":"another"},"name":"coffee"}"#
        )

        XCTAssertTrue(result.contains(#""token":"<redacted>""#))
        XCTAssertTrue(result.contains(#""refreshToken":"<redacted>""#))
        XCTAssertTrue(result.contains(#""name":"coffee""#))
    }

    func testSanitizeBodyKeepsBinaryMarkerUntouched() {
        let sut = AppLogSanitizer()

        let result = sut.sanitizeBody("<128 bytes binary>")

        XCTAssertEqual(result, "<128 bytes binary>")
    }
}
