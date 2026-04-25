import Foundation

protocol ForgotPasswordBusinessLogic: Sendable {
    func fetchData() async
}

protocol ForgotPasswordHandler: AnyObject, Sendable {
    func handleEmailDidChange(_ email: String) async
    func handleTapSend() async
    func handleTapClose() async
}

actor ForgotPasswordInteractor: ForgotPasswordBusinessLogic {
    private let passwordRestorationService: PasswordRestorationContractServicing
    private let presenter: ForgotPasswordPresentationLogic
    private let router: ForgotPasswordRoutingLogic

    private var loadingState: LoadingStatus = .idle
    private var email = ""
    private var emailErrorMessage: String?

    init(
        passwordRestorationService: PasswordRestorationContractServicing,
        presenter: ForgotPasswordPresentationLogic,
        router: ForgotPasswordRoutingLogic
    ) {
        self.passwordRestorationService = passwordRestorationService
        self.presenter = presenter
        self.router = router
    }

    func fetchData() async {
        await presentFetchedData()
    }
}

private extension ForgotPasswordInteractor {
    func presentFetchedData() async {
        await presenter.presentFetchedData(
            ForgotPasswordFetchData(
                loadingState: loadingState,
                email: email,
                emailErrorMessage: emailErrorMessage
            )
        )
    }

    func validateEmail() -> Bool {
        emailErrorMessage = nil

        if normalizedEmail.isEmpty {
            emailErrorMessage = L10n.commonFillField
        } else if !normalizedEmail.isValidEmail {
            emailErrorMessage = L10n.registrationErrorInvalidEmail
        }

        return emailErrorMessage == nil
    }

    var normalizedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension ForgotPasswordInteractor: ForgotPasswordHandler {
    func handleEmailDidChange(_ email: String) async {
        self.email = email
        emailErrorMessage = nil
    }

    func handleTapSend() async {
        if case .loading = loadingState {
            return
        }

        guard validateEmail() else {
            loadingState = .idle
            await presentFetchedData()
            return
        }

        do {
            loadingState = .loading
            await presentFetchedData()

            try await passwordRestorationService.requestPasswordReset(
                ForgotPasswordRequestDTO(email: normalizedEmail)
            )

            loadingState = .loaded
            await presentFetchedData()
            await router.presentSuccess(with: L10n.forgotPasswordSuccessMessage)
            await router.close()
        } catch {
            loadingState = .failed(.undelinedError(description: error.localizedDescription))
            await presentFetchedData()
            await router.presentError(with: error.localizedDescription)
        }
    }

    func handleTapClose() async {
        await router.close()
    }
}
