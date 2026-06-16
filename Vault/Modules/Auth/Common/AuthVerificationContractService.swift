import Foundation
@preconcurrency import NetworkClient

struct AuthVerificationChallenge: Equatable, Sendable {
    let email: String
    let expiresIn: Int
    let resendAvailableIn: Int
}

enum AuthVerificationContractError: Error, Equatable {
    case unverified(AuthVerificationChallenge)
    case invalidCredentials
    case invalidCode
    case resendTooSoon
    case emailAlreadyRegistered
    case invalidRequest
    case emailSendFailed
    case emailVerificationNotConfigured
    case serverError
}

extension AuthVerificationContractError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .unverified:
            L10n.authVerificationErrorUnverified
        case .invalidCredentials:
            L10n.authVerificationErrorInvalidCredentials
        case .invalidCode:
            L10n.authVerificationErrorInvalidCode
        case .resendTooSoon:
            L10n.authVerificationErrorResendTooSoon
        case .emailAlreadyRegistered:
            L10n.authVerificationErrorEmailAlreadyRegistered
        case .invalidRequest:
            L10n.authVerificationErrorInvalidRequest
        case .emailSendFailed:
            L10n.authVerificationErrorEmailSendFailed
        case .emailVerificationNotConfigured:
            L10n.authVerificationErrorEmailVerificationNotConfigured
        case .serverError:
            L10n.authVerificationErrorServer
        }
    }
}

enum AuthVerificationContractErrorMapper {
    static func map(_ response: AuthErrorResponseDTO) -> AuthVerificationContractError {
        switch response.error {
        case "unverified":
            return .unverified(
                AuthVerificationChallenge(
                    email: response.email ?? "",
                    expiresIn: response.expiresIn ?? 0,
                    resendAvailableIn: response.resendAvailableIn ?? 0
                )
            )
        case "invalid credentials", "invalid_credentials", "user not found", "user_not_found":
            return .invalidCredentials
        case "invalid_code", "expired_code", "too_many_attempts", "code_not_found", "already_verified":
            return .invalidCode
        case "resend_too_soon":
            return .resendTooSoon
        case "email_already_registered":
            return .emailAlreadyRegistered
        case "invalid_request", "invalid request":
            return .invalidRequest
        case "email_send_failed":
            return .emailSendFailed
        case "email verification not configured", "email_verification_not_configured":
            return .emailVerificationNotConfigured
        case "server_error", "server error":
            return .serverError
        default:
            return .serverError
        }
    }
}

protocol AuthVerificationContractServicing: Sendable {
    func startEmailRegistration(_ request: RegisterRequestDTO) async throws -> EmailVerificationChallengeResponseDTO
    func verifyEmail(_ request: EmailVerificationRequestDTO) async throws -> LoginResponseDTO
    func resendEmailVerification(_ request: EmailVerificationResendRequestDTO) async throws -> EmailVerificationChallengeResponseDTO
    func login(_ request: LoginRequestDTO) async throws -> LoginResponseDTO
}

final class AuthVerificationContractService: AuthVerificationContractServicing {
    private let networkClient: AsyncNetworkClient

    init(networkClient: AsyncNetworkClient) {
        self.networkClient = networkClient
    }

    func startEmailRegistration(_ request: RegisterRequestDTO) async throws -> EmailVerificationChallengeResponseDTO {
        do {
            return try await networkClient.request(
                inBodyError: AuthErrorResponseDTO.self,
                AuthAPI.registerEmailStart(request),
                responseType: EmailVerificationChallengeResponseDTO.self
            )
        } catch {
            throw resolveError(from: error)
        }
    }

    func verifyEmail(_ request: EmailVerificationRequestDTO) async throws -> LoginResponseDTO {
        do {
            return try await networkClient.request(
                inBodyError: AuthErrorResponseDTO.self,
                AuthAPI.registerEmailVerify(request),
                responseType: LoginResponseDTO.self
            )
        } catch {
            throw resolveError(from: error)
        }
    }

    func resendEmailVerification(_ request: EmailVerificationResendRequestDTO) async throws -> EmailVerificationChallengeResponseDTO {
        do {
            return try await networkClient.request(
                inBodyError: AuthErrorResponseDTO.self,
                AuthAPI.registerEmailResend(request),
                responseType: EmailVerificationChallengeResponseDTO.self
            )
        } catch {
            throw resolveError(from: error)
        }
    }

    func login(_ request: LoginRequestDTO) async throws -> LoginResponseDTO {
        do {
            return try await networkClient.request(
                inBodyError: AuthErrorResponseDTO.self,
                AuthAPI.login(request),
                responseType: LoginResponseDTO.self
            )
        } catch {
            throw resolveError(from: error)
        }
    }
}

private extension AuthVerificationContractService {
    func resolveError(from error: Error) -> Error {
        guard case let NetworkClientError.inBodyError(customError, _) = error,
              let response = customError as? AuthErrorResponseDTO else {
            return error
        }

        return AuthVerificationContractErrorMapper.map(response)
    }
}
