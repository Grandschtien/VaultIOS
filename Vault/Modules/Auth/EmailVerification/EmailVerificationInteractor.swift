import Foundation

protocol EmailVerificationBusinessLogic: Sendable {
    func fetchData() async
    func handleFlowDidExit() async
}

protocol EmailVerificationHandler: AnyObject, Sendable {
    func handleCodeDidChange(_ code: String) async
    func handleTapVerify() async
    func handleTapResend() async
}

actor EmailVerificationInteractor: EmailVerificationBusinessLogic {
    private let authVerificationService: AuthVerificationContractServicing
    private let presenter: EmailVerificationPresentationLogic
    private let router: EmailVerificationRoutingLogic
    private let tokenStorageService: TokenStorageServiceProtocol
    private let userProfileStorageService: UserProfileStorageServiceProtocol
    private let subscriptionInitializer: SubscriptionInitializerLogic
    private let widgetSnapshotSyncService: VylokWidgetSnapshotSyncing
    private let context: EmailVerificationContext
    private let registrationStorage: RegistrationStorageProtocol?

    private var loadingState: LoadingStatus = .idle
    private var code = ""
    private var resendAvailableIn: Int
    private var errorMessage: String?
    private var countdownTask: Task<Void, Never>?

    init(
        authVerificationService: AuthVerificationContractServicing,
        presenter: EmailVerificationPresentationLogic,
        router: EmailVerificationRoutingLogic,
        tokenStorageService: TokenStorageServiceProtocol,
        userProfileStorageService: UserProfileStorageServiceProtocol,
        subscriptionInitializer: SubscriptionInitializerLogic,
        widgetSnapshotSyncService: VylokWidgetSnapshotSyncing,
        context: EmailVerificationContext,
        registrationStorage: RegistrationStorageProtocol?
    ) {
        self.authVerificationService = authVerificationService
        self.presenter = presenter
        self.router = router
        self.tokenStorageService = tokenStorageService
        self.userProfileStorageService = userProfileStorageService
        self.subscriptionInitializer = subscriptionInitializer
        self.widgetSnapshotSyncService = widgetSnapshotSyncService
        self.context = context
        self.registrationStorage = registrationStorage
        self.resendAvailableIn = context.resendAvailableIn
    }

    func fetchData() async {
        startCountdownIfNeeded()
        await presentFetchedData()
    }

    func handleFlowDidExit() async {
        countdownTask?.cancel()
        countdownTask = nil
    }
}

private extension EmailVerificationInteractor {
    func presentFetchedData() async {
        await presenter.presentFetchedData(
            EmailVerificationFetchData(
                loadingState: loadingState,
                email: context.email,
                code: code,
                resendAvailableIn: resendAvailableIn,
                errorMessage: errorMessage
            )
        )
    }

    func startCountdownIfNeeded() {
        countdownTask?.cancel()

        guard resendAvailableIn > 0 else {
            countdownTask = nil
            return
        }

        let interactor = self
        countdownTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                await interactor.handleCountdownTick()
            }
        }
    }

    func handleCountdownTick() async {
        guard resendAvailableIn > 0 else {
            countdownTask?.cancel()
            countdownTask = nil
            return
        }

        resendAvailableIn -= 1
        await presentFetchedData()

        if resendAvailableIn == 0 {
            countdownTask?.cancel()
            countdownTask = nil
        }
    }

    func sanitizedCode(_ code: String) -> String {
        String(code.filter(\.isNumber).prefix(6))
    }

    func applyAuthSession(_ response: LoginResponseDTO) async {
        tokenStorageService.setToken(
            AuthTokenDTO(
                accessToken: response.accessToken,
                refreshToken: response.refreshToken,
                tokenType: response.tokenType,
                expiresIn: response.expiresIn
            )
        )
        userProfileStorageService.saveProfile(UserProfileDefaults(user: response.user))
        await subscriptionInitializer.setUserId(response.user.id)
        await widgetSnapshotSyncService.syncSnapshot()
    }

    func inlineErrorMessage(for error: AuthVerificationContractError) -> String? {
        switch error {
        case .invalidCode:
            L10n.emailVerificationInvalidCode
        default:
            nil
        }
    }
}

extension EmailVerificationInteractor: EmailVerificationHandler {
    func handleCodeDidChange(_ code: String) async {
        self.code = sanitizedCode(code)
        errorMessage = nil
        await presentFetchedData()

        guard self.code.count == 6 else {
            return
        }

        await handleTapVerify()
    }

    func handleTapVerify() async {
        guard loadingState != .loading else {
            return
        }

        guard code.count == 6 else {
            loadingState = .idle
            errorMessage = L10n.commonFillField
            await presentFetchedData()
            return
        }

        do {
            loadingState = .loading
            errorMessage = nil
            await presentFetchedData()

            let response = try await authVerificationService.verifyEmail(
                EmailVerificationRequestDTO(
                    email: context.email,
                    code: code
                )
            )

            countdownTask?.cancel()
            countdownTask = nil
            await applyAuthSession(response)

            if context.source == .registration {
                await registrationStorage?.clear()
            }

            loadingState = .loaded
            await presentFetchedData()
            await router.openMainFlow()
        } catch let error as AuthVerificationContractError {
            loadingState = .idle

            if let errorMessage = inlineErrorMessage(for: error) {
                self.errorMessage = errorMessage
                await presentFetchedData()
                return
            }

            await presentFetchedData()
            await router.presentError(with: error.localizedDescription)
        } catch {
            loadingState = .failed(.undelinedError(description: error.localizedDescription))
            await presentFetchedData()
            await router.presentError(with: error.localizedDescription)
        }
    }

    func handleTapResend() async {
        guard loadingState != .loading, resendAvailableIn == 0 else {
            return
        }

        do {
            loadingState = .loading
            await presentFetchedData()

            let challenge = try await authVerificationService.resendEmailVerification(
                EmailVerificationResendRequestDTO(email: context.email)
            )

            loadingState = .loaded
            code = ""
            errorMessage = nil
            resendAvailableIn = max(0, challenge.resendAvailableIn)
            startCountdownIfNeeded()
            await presentFetchedData()
        } catch let error as AuthVerificationContractError {
            loadingState = .idle
            await presentFetchedData()
            await router.presentError(with: error.localizedDescription)
        } catch {
            loadingState = .failed(.undelinedError(description: error.localizedDescription))
            await presentFetchedData()
            await router.presentError(with: error.localizedDescription)
        }
    }
}
