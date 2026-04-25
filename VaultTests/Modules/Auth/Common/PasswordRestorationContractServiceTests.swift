import XCTest
@testable import Vault

final class PasswordRestorationContractServiceTests: XCTestCase {
    func testRequestPasswordResetForwardsPayload() async throws {
        let spy = AsyncNetworkClientContractSpy()
        let request = ForgotPasswordRequestDTO(email: "jane@example.com")
        var capturedRequest: ForgotPasswordRequestDTO?

        spy.onRequestWithoutResponse = { target in
            guard let api = target as? AuthAPI,
                  case let .forgotPassword(payload) = api else {
                return XCTFail("Expected AuthAPI.forgotPassword")
            }

            capturedRequest = payload
        }

        let sut = PasswordRestorationContractService(networkClient: spy)
        try await sut.requestPasswordReset(request)

        XCTAssertEqual(capturedRequest, request)
    }

    func testResetPasswordForwardsPayload() async throws {
        let spy = AsyncNetworkClientContractSpy()
        let request = ResetPasswordRequestDTO(
            token: "token-123",
            password: "newpassword123"
        )
        var capturedRequest: ResetPasswordRequestDTO?

        spy.onRequestWithoutResponse = { target in
            guard let api = target as? AuthAPI,
                  case let .resetPassword(payload) = api else {
                return XCTFail("Expected AuthAPI.resetPassword")
            }

            capturedRequest = payload
        }

        let sut = PasswordRestorationContractService(networkClient: spy)
        try await sut.resetPassword(request)

        XCTAssertEqual(capturedRequest, request)
    }
}

extension PasswordRestorationContractServiceTests {
    func testRequestPasswordResetWhenClientFailsRethrowsError() async {
        let spy = AsyncNetworkClientContractSpy()
        spy.nextError = StubError.any

        let sut = PasswordRestorationContractService(networkClient: spy)

        do {
            try await sut.requestPasswordReset(
                ForgotPasswordRequestDTO(email: "jane@example.com")
            )
            XCTFail("Expected throw")
        } catch {
            XCTAssertNotNil(error as? StubError)
        }
    }

    func testResetPasswordWhenClientFailsRethrowsError() async {
        let spy = AsyncNetworkClientContractSpy()
        spy.nextError = StubError.any

        let sut = PasswordRestorationContractService(networkClient: spy)

        do {
            try await sut.resetPassword(
                ResetPasswordRequestDTO(
                    token: "token-123",
                    password: "newpassword123"
                )
            )
            XCTFail("Expected throw")
        } catch {
            XCTAssertNotNil(error as? StubError)
        }
    }
}

private extension PasswordRestorationContractServiceTests {
    enum StubError: LocalizedError {
        case any

        var errorDescription: String? {
            "stub-error"
        }
    }
}
