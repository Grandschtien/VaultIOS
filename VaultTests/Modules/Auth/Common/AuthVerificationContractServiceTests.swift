import XCTest
@testable import Vault

final class AuthVerificationContractServiceTests: XCTestCase {
    func testStartEmailRegistrationForwardsPayload() async throws {
        let spy = AsyncNetworkClientContractSpy()
        let request = RegisterRequestDTO(
            provider: "password",
            email: "jane@example.com",
            password: "secret123",
            name: "Jane Doe",
            currency: "USD",
            preferredLanguage: "en"
        )
        var capturedRequest: RegisterRequestDTO?

        spy.setResponse(
            json: """
            {
              "status": "code_sent",
              "email": "jane@example.com",
              "expires_in": 600,
              "resend_available_in": 60
            }
            """
        )
        spy.onRequest = { target in
            guard let api = target as? AuthAPI,
                  case let .registerEmailStart(payload) = api else {
                return XCTFail("Expected AuthAPI.registerEmailStart")
            }

            capturedRequest = payload
        }

        let sut = AuthVerificationContractService(networkClient: spy)
        _ = try await sut.startEmailRegistration(request)

        XCTAssertEqual(capturedRequest, request)
    }

    func testVerifyEmailForwardsPayload() async throws {
        let spy = AsyncNetworkClientContractSpy()
        let request = EmailVerificationRequestDTO(
            email: "jane@example.com",
            code: "123456"
        )
        var capturedRequest: EmailVerificationRequestDTO?

        spy.setResponse(
            json: """
            {
              "access_token": "access",
              "refresh_token": "refresh",
              "token_type": "Bearer",
              "expires_in": 900,
              "user": {
                "id": "1",
                "email": "jane@example.com",
                "email_verified": true,
                "name": "Jane Doe",
                "currency": "USD",
                "preferred_language": "en",
                "tier": "REGULAR"
              }
            }
            """
        )
        spy.onRequest = { target in
            guard let api = target as? AuthAPI,
                  case let .registerEmailVerify(payload) = api else {
                return XCTFail("Expected AuthAPI.registerEmailVerify")
            }

            capturedRequest = payload
        }

        let sut = AuthVerificationContractService(networkClient: spy)
        _ = try await sut.verifyEmail(request)

        XCTAssertEqual(capturedRequest, request)
    }

    func testResendEmailVerificationForwardsPayload() async throws {
        let spy = AsyncNetworkClientContractSpy()
        let request = EmailVerificationResendRequestDTO(email: "jane@example.com")
        var capturedRequest: EmailVerificationResendRequestDTO?

        spy.setResponse(
            json: """
            {
              "status": "code_sent",
              "email": "jane@example.com",
              "expires_in": 600,
              "resend_available_in": 60
            }
            """
        )
        spy.onRequest = { target in
            guard let api = target as? AuthAPI,
                  case let .registerEmailResend(payload) = api else {
                return XCTFail("Expected AuthAPI.registerEmailResend")
            }

            capturedRequest = payload
        }

        let sut = AuthVerificationContractService(networkClient: spy)
        _ = try await sut.resendEmailVerification(request)

        XCTAssertEqual(capturedRequest, request)
    }

    func testLoginForwardsPayload() async throws {
        let spy = AsyncNetworkClientContractSpy()
        let request = LoginRequestDTO(
            provider: .password,
            email: "jane@example.com",
            password: "secret123"
        )
        var capturedRequest: LoginRequestDTO?

        spy.setResponse(
            json: """
            {
              "access_token": "access",
              "refresh_token": "refresh",
              "token_type": "Bearer",
              "expires_in": 900,
              "user": {
                "id": "1",
                "email": "jane@example.com",
                "email_verified": true,
                "name": "Jane Doe",
                "currency": "USD",
                "preferred_language": "en",
                "tier": "REGULAR"
              }
            }
            """
        )
        spy.onRequest = { target in
            guard let api = target as? AuthAPI,
                  case let .login(payload) = api else {
                return XCTFail("Expected AuthAPI.login")
            }

            capturedRequest = payload
        }

        let sut = AuthVerificationContractService(networkClient: spy)
        _ = try await sut.login(request)

        XCTAssertEqual(capturedRequest, request)
    }
}

extension AuthVerificationContractServiceTests {
    func testLocalizedDescriptionsUseLocalizedStrings() {
        XCTAssertEqual(AuthVerificationContractError.unverified(.init(email: "", expiresIn: 0, resendAvailableIn: 0)).localizedDescription, L10n.authVerificationErrorUnverified)
        XCTAssertEqual(AuthVerificationContractError.invalidCredentials.localizedDescription, L10n.authVerificationErrorInvalidCredentials)
        XCTAssertEqual(AuthVerificationContractError.invalidCode.localizedDescription, L10n.authVerificationErrorInvalidCode)
        XCTAssertEqual(AuthVerificationContractError.resendTooSoon.localizedDescription, L10n.authVerificationErrorResendTooSoon)
        XCTAssertEqual(AuthVerificationContractError.emailAlreadyRegistered.localizedDescription, L10n.authVerificationErrorEmailAlreadyRegistered)
        XCTAssertEqual(AuthVerificationContractError.invalidRequest.localizedDescription, L10n.authVerificationErrorInvalidRequest)
        XCTAssertEqual(AuthVerificationContractError.emailSendFailed.localizedDescription, L10n.authVerificationErrorEmailSendFailed)
        XCTAssertEqual(AuthVerificationContractError.emailVerificationNotConfigured.localizedDescription, L10n.authVerificationErrorEmailVerificationNotConfigured)
        XCTAssertEqual(AuthVerificationContractError.serverError.localizedDescription, L10n.authVerificationErrorServer)
    }

    func testErrorMapperMapsUnverifiedPayload() {
        let error = AuthVerificationContractErrorMapper.map(
            AuthErrorResponseDTO(
                error: "unverified",
                email: "jane@example.com",
                expiresIn: 600,
                resendAvailableIn: 60
            )
        )

        XCTAssertEqual(
            error,
            .unverified(
                AuthVerificationChallenge(
                    email: "jane@example.com",
                    expiresIn: 600,
                    resendAvailableIn: 60
                )
            )
        )
    }

    func testErrorMapperMapsCredentialErrorsToInvalidCredentials() {
        XCTAssertEqual(
            AuthVerificationContractErrorMapper.map(
                AuthErrorResponseDTO(
                    error: "invalid_credentials",
                    email: nil,
                    expiresIn: nil,
                    resendAvailableIn: nil
                )
            ),
            .invalidCredentials
        )
        XCTAssertEqual(
            AuthVerificationContractErrorMapper.map(
                AuthErrorResponseDTO(
                    error: "user_not_found",
                    email: nil,
                    expiresIn: nil,
                    resendAvailableIn: nil
                )
            ),
            .invalidCredentials
        )
    }

    func testErrorMapperMapsVerificationCodeStateErrorsToInvalidCode() {
        XCTAssertEqual(
            AuthVerificationContractErrorMapper.map(
                AuthErrorResponseDTO(
                    error: "invalid_code",
                    email: nil,
                    expiresIn: nil,
                    resendAvailableIn: nil
                )
            ),
            .invalidCode
        )
        XCTAssertEqual(
            AuthVerificationContractErrorMapper.map(
                AuthErrorResponseDTO(
                    error: "expired_code",
                    email: nil,
                    expiresIn: nil,
                    resendAvailableIn: nil
                )
            ),
            .invalidCode
        )
        XCTAssertEqual(
            AuthVerificationContractErrorMapper.map(
                AuthErrorResponseDTO(
                    error: "too_many_attempts",
                    email: nil,
                    expiresIn: nil,
                    resendAvailableIn: nil
                )
            ),
            .invalidCode
        )
        XCTAssertEqual(
            AuthVerificationContractErrorMapper.map(
                AuthErrorResponseDTO(
                    error: "code_not_found",
                    email: nil,
                    expiresIn: nil,
                    resendAvailableIn: nil
                )
            ),
            .invalidCode
        )
        XCTAssertEqual(
            AuthVerificationContractErrorMapper.map(
                AuthErrorResponseDTO(
                    error: "already_verified",
                    email: nil,
                    expiresIn: nil,
                    resendAvailableIn: nil
                )
            ),
            .invalidCode
        )
    }

    func testErrorMapperKeepsNonCodeVerificationErrorsSeparated() {
        XCTAssertEqual(
            AuthVerificationContractErrorMapper.map(
                AuthErrorResponseDTO(
                    error: "resend_too_soon",
                    email: nil,
                    expiresIn: nil,
                    resendAvailableIn: nil
                )
            ),
            .resendTooSoon
        )
    }
}
