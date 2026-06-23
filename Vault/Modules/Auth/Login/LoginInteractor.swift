// Created by Egor Shkarin 14.03.2026

import Foundation
@preconcurrency import NetworkClient

protocol LoginBusinessLogic: Sendable {
    func fetchData() async
}

protocol LoginHandler: AnyObject, Sendable {
    func handleEmailDidChange(_ email: String) async
    func handlePasswordDidChange(_ password: String) async
    func handleSignInDidTap() async
    func handleSignUpDidTap() async
    func handleForgotDidTap() async
}

actor LoginInteractor: LoginBusinessLogic {
    enum LocalError: Error {
        case emptyEmail
        case emptyPassword
    }
    private let authVerificationService: AuthVerificationContractServicing
    private let presenter: LoginPresentationLogic
    private let router: LoginRoutingLogic
    private let tokenStorageService: TokenStorageServiceProtocol
    private let userProfileStorageService: UserProfileStorageServiceProtocol
    private let subscriptionInitializerLogic: SubscriptionInitializerLogic
    private let widgetSnapshotSyncService: VylokWidgetSnapshotSyncing
    private let analytics: LoginAnalyticsTracking?
    
    private var email: String = ""
    private var password: String = ""

    init(
        authVerificationService: AuthVerificationContractServicing,
        presenter: LoginPresentationLogic,
        router: LoginRoutingLogic,
        tokenStorageService: TokenStorageServiceProtocol,
        subscriptionInitializerLogic: SubscriptionInitializerLogic,
        userProfileStorageService: UserProfileStorageServiceProtocol,
        widgetSnapshotSyncService: VylokWidgetSnapshotSyncing,
        analytics: LoginAnalyticsTracking? = nil
    ) {
        self.authVerificationService = authVerificationService
        self.presenter = presenter
        self.router = router
        self.tokenStorageService = tokenStorageService
        self.userProfileStorageService = userProfileStorageService
        self.subscriptionInitializerLogic = subscriptionInitializerLogic
        self.widgetSnapshotSyncService = widgetSnapshotSyncService
        self.analytics = analytics
    }

    func fetchData() async {
        analytics?.trackScreenOpen()
        await presentFetchedData(.idle)
    }
}

private extension LoginInteractor {
    func presentFetchedData(_ loadingStatus: LoadingStatus) async {
        await presenter.presentFetchedData(
            LoginFetchData(
                loadingState: loadingStatus,
                email: email,
                password: password
            )
        )
    }
}

extension LoginInteractor: LoginHandler {
    func handleEmailDidChange(_ email: String) async {
        self.email = email
    }

    func handlePasswordDidChange(_ password: String) async {
        self.password = password
    }

    func handleSignInDidTap() async {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalizedEmail.isEmpty else {
            await presentFetchedData(.failed(.undelinedError(description: LocalError.emptyEmail.localizedDescription)))
            return
        }
        
        guard !normalizedPassword.isEmpty else {
            await presentFetchedData(.failed(.undelinedError(description: LocalError.emptyPassword.localizedDescription)))
            return
        }

        do {
            await presentFetchedData(.loading)
            let result = try await authVerificationService.login(
                LoginRequestDTO(
                    provider: .password,
                    email: normalizedEmail,
                    password: normalizedPassword
                )
            )

            tokenStorageService.setToken(
                AuthTokenDTO(
                    accessToken: result.accessToken,
                    refreshToken: result.refreshToken,
                    tokenType: result.tokenType,
                    expiresIn: result.expiresIn
                )
            )
            userProfileStorageService.saveProfile(
                UserProfileDefaults(user: result.user)
            )

            await subscriptionInitializerLogic.setUserId(result.user.id)
            await widgetSnapshotSyncService.syncSnapshot()
            await presentFetchedData(.loaded)
            analytics?.trackLoginSuccess()
            await router.openMainFlow()
        } catch let error as AuthVerificationContractError {
            if case let .unverified(challenge) = error {
                await presentFetchedData(.idle)
                await router.openEmailVerification(
                    context: EmailVerificationContext(
                        source: .login,
                        email: challenge.email,
                        expiresIn: challenge.expiresIn,
                        resendAvailableIn: challenge.resendAvailableIn
                    )
                )
                return
            }

            analytics?.trackLoginFailure(error)
            await presentFetchedData(.failed(.undelinedError(description: error.localizedDescription)))
            await router.presentError(with: error.localizedDescription)
        } catch {
            analytics?.trackLoginFailure(error)
            await presentFetchedData(.failed(.undelinedError(description: error.localizedDescription)))
            await router.presentError(with: error.localizedDescription)
        }
    }

    func handleSignUpDidTap() async {
        await router.openRegistration()
    }

    func handleForgotDidTap() async {
        await router.openForgetPasswordScreen(
            context: ForgotPasswordContext(email: email)
        )
    }
}
