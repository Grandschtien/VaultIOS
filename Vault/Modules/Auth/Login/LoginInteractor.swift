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
    private let networkClient: AsyncNetworkClient
    private let presenter: LoginPresentationLogic
    private let router: LoginRoutingLogic
    private let tokenStorageService: TokenStorageServiceProtocol

    private var email: String = ""
    private var password: String = ""

    init(
        networkClient: AsyncNetworkClient,
        presenter: LoginPresentationLogic,
        router: LoginRoutingLogic,
        tokenStorageService: TokenStorageServiceProtocol
    ) {
        self.networkClient = networkClient
        self.presenter = presenter
        self.router = router
        self.tokenStorageService = tokenStorageService
    }

    func fetchData() async {
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
        do {
            await presentFetchedData(.loading)
            let result = try await networkClient.request(
                AuthAPI.login(
                    LoginRequestDTO(
                        provider: .password,
                        email: email,
                        password: password
                    )
                ),
                responseType: LoginResponseDTO.self
            )

            tokenStorageService.setToken(
                AuthTokenDTO(
                    accessToken: result.accessToken,
                    refreshToken: result.refreshToken,
                    tokenType: result.tokenType,
                    expiresIn: result.expiresIn
                )
            )

            await presentFetchedData(.loaded)
        } catch {
            await presentFetchedData(.failed(error))
        }
    }

    func handleSignUpDidTap() async {
        await router.openRegistration()
    }

    func handleForgotDidTap() async {
        await router.openForgetPasswordScreen()
    }
}
