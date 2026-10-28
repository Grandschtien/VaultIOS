import XCTest
@testable import Vylok

final class LaunchEnvironmentProviderTests: XCTestCase {
    func testAPIBaseURLKeepsSchemeHostAndPort() {
        let sut = LaunchEnvironmentProvider(
            environment: ["VAULT_API_BASE_URL": "http://localhost:8080"],
            isOverrideAllowed: true
        )

        XCTAssertEqual(sut.apiBaseURL?.scheme, "http")
        XCTAssertEqual(sut.apiBaseURL?.host, "localhost")
        XCTAssertEqual(sut.apiBaseURL?.port, 8080)
    }
}

extension LaunchEnvironmentProviderTests {
    func testAPIBaseURLIsNilWhenVariableIsMissing() {
        let sut = LaunchEnvironmentProvider(environment: [:], isOverrideAllowed: true)

        XCTAssertNil(sut.apiBaseURL)
    }

    func testAPIBaseURLIsNilForMalformedValue() {
        let sut = LaunchEnvironmentProvider(
            environment: ["VAULT_API_BASE_URL": "localhost:8080"],
            isOverrideAllowed: true
        )

        XCTAssertNil(sut.apiBaseURL)
    }

    func testAPIBaseURLIsNilWhenOverridesAreNotAllowed() {
        let sut = LaunchEnvironmentProvider(
            environment: ["VAULT_API_BASE_URL": "http://localhost:8080"],
            isOverrideAllowed: false
        )

        XCTAssertNil(sut.apiBaseURL)
    }
}

extension LaunchEnvironmentProviderTests {
    func testQAModeIsEnabledForOne() {
        let sut = LaunchEnvironmentProvider(environment: ["VAULT_QA_MODE": "1"], isOverrideAllowed: true)

        XCTAssertTrue(sut.isQAMode)
    }

    func testQAModeIsDisabledForOtherValues() {
        let sut = LaunchEnvironmentProvider(environment: ["VAULT_QA_MODE": "true"], isOverrideAllowed: true)

        XCTAssertFalse(sut.isQAMode)
    }

    func testQAModeIsDisabledWhenOverridesAreNotAllowed() {
        let sut = LaunchEnvironmentProvider(environment: ["VAULT_QA_MODE": "1"], isOverrideAllowed: false)

        XCTAssertFalse(sut.isQAMode)
    }
}

extension LaunchEnvironmentProviderTests {
    func testQASessionIsReturnedInQAMode() {
        let sut = LaunchEnvironmentProvider(
            environment: ["VAULT_QA_MODE": "1", "VAULT_QA_SESSION": "{}"],
            isOverrideAllowed: true
        )

        XCTAssertEqual(sut.qaSession, "{}")
    }

    func testQASessionIsNilOutsideQAMode() {
        let sut = LaunchEnvironmentProvider(environment: ["VAULT_QA_SESSION": "{}"], isOverrideAllowed: true)

        XCTAssertNil(sut.qaSession)
    }

    func testQASessionIsNilForEmptyValue() {
        let sut = LaunchEnvironmentProvider(
            environment: ["VAULT_QA_MODE": "1", "VAULT_QA_SESSION": ""],
            isOverrideAllowed: true
        )

        XCTAssertNil(sut.qaSession)
    }
}
