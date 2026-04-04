import XCTest
@testable import Vault

@MainActor
final class ProfileInteractorTests: XCTestCase {
    func testFetchDataSuccessPublishesLoadingThenLoaded() async {
        let presenter = ProfilePresenterSpy()
        let router = ProfileRouterSpy()
        let profileService = ProfileServiceStub(
            results: [
                .success(
                    .init(
                        id: "user-1",
                        email: "sarah@example.com",
                        name: "Sarah Connor",
                        currency: "GBP",
                        preferredLanguage: "en-GB",
                        tier: "PREMIUM",
                        tierValidUntil: nil
                    )
                )
            ]
        )
        let sut = makeSut(
            presenter: presenter,
            router: router,
            profileService: profileService
        )

        await sut.fetchData()

        guard let first = presenter.presentedData.first,
              let last = presenter.presentedData.last else {
            return XCTFail("Expected presenter updates")
        }

        assertStatus(first.loadingState, is: .loading)
        assertStatus(last.loadingState, is: .loaded)
        XCTAssertEqual(last.profile?.name, "Sarah Connor")

        let serviceCallsCount = await profileService.callsCount()
        XCTAssertEqual(serviceCallsCount, 1)
    }
}

extension ProfileInteractorTests {
    func testFetchDataInitialLoadingUsesCurrencyFromLocalProfileStorage() async {
        let presenter = ProfilePresenterSpy()
        let router = ProfileRouterSpy()
        let profileService = ProfileServiceStub(
            results: [
                .success(
                    .init(
                        id: "user-1",
                        email: "sarah@example.com",
                        name: "Sarah Connor",
                        currency: "USD",
                        preferredLanguage: "en-US",
                        tier: "ACTIVE",
                        tierValidUntil: nil
                    )
                )
            ]
        )
        let localProfileStorage = UserProfileStorageServiceSpy(
            storedProfile: .init(
                userId: "local-1",
                email: "local@example.com",
                name: "Local User",
                currency: "KZT",
                language: "en-US"
            )
        )
        let sut = makeSut(
            presenter: presenter,
            router: router,
            profileService: profileService,
            localProfileStorage: localProfileStorage
        )

        await sut.fetchData()

        guard presenter.presentedData.count >= 2 else {
            return XCTFail("Expected loading and loaded presenter states")
        }

        let loadingState = presenter.presentedData[0]
        let loadedState = presenter.presentedData[1]

        XCTAssertEqual(loadingState.selectedCurrencyCode, "KZT")
        XCTAssertEqual(loadedState.selectedCurrencyCode, "USD")
    }
}

extension ProfileInteractorTests {
    func testFetchDataFailurePublishesFailedState() async {
        let presenter = ProfilePresenterSpy()
        let router = ProfileRouterSpy()
        let profileService = ProfileServiceStub(
            results: [.failure(StubError.any)]
        )
        let sut = makeSut(
            presenter: presenter,
            router: router,
            profileService: profileService
        )

        await sut.fetchData()

        guard let first = presenter.presentedData.first,
              let last = presenter.presentedData.last else {
            return XCTFail("Expected presenter updates")
        }

        assertStatus(first.loadingState, is: .loading)
        assertStatus(last.loadingState, is: .failed)

        let serviceCallsCount = await profileService.callsCount()
        XCTAssertEqual(serviceCallsCount, 1)
    }
}

extension ProfileInteractorTests {
    func testHandleTapRetryRepeatsFetchFlow() async {
        let presenter = ProfilePresenterSpy()
        let router = ProfileRouterSpy()
        let profileService = ProfileServiceStub(
            results: [
                .failure(StubError.any),
                .success(
                    .init(
                        id: "user-1",
                        email: nil,
                        name: "Sarah Connor",
                        currency: "USD",
                        preferredLanguage: "en-US",
                        tier: "ACTIVE",
                        tierValidUntil: nil
                    )
                )
            ]
        )
        let sut = makeSut(
            presenter: presenter,
            router: router,
            profileService: profileService
        )

        await sut.fetchData()
        await sut.handleTapRetry()

        guard let last = presenter.presentedData.last else {
            return XCTFail("Expected presenter updates")
        }

        assertStatus(last.loadingState, is: .loaded)
        XCTAssertEqual(last.profile?.tier, "ACTIVE")

        let serviceCallsCount = await profileService.callsCount()
        XCTAssertEqual(serviceCallsCount, 2)
    }
}

extension ProfileInteractorTests {
    func testHandleTapLogoutWhenBackendRequestSucceedsDoesNotPresentError() async {
        let presenter = ProfilePresenterSpy()
        let router = ProfileRouterSpy()
        let profileService = ProfileServiceStub(results: [])
        let authSessionService = AuthSessionServiceSpy(logoutResult: .success(()))
        let sut = makeSut(
            presenter: presenter,
            router: router,
            profileService: profileService,
            authSessionService: authSessionService
        )

        await sut.handleTapLogout()

        XCTAssertTrue(router.presentedErrors.isEmpty)
        XCTAssertEqual(presenter.presentedData.last?.isLoggingOut, true)
        let logoutCallsCount = await authSessionService.currentLogoutFromBackendCallsCount()
        XCTAssertEqual(logoutCallsCount, 1)
    }
}

extension ProfileInteractorTests {
    func testHandleTapLogoutWhenBackendRequestFailsPresentsErrorToast() async {
        let presenter = ProfilePresenterSpy()
        let router = ProfileRouterSpy()
        let profileService = ProfileServiceStub(results: [])
        let authSessionService = AuthSessionServiceSpy(logoutResult: .failure(StubError.any))
        let sut = makeSut(
            presenter: presenter,
            router: router,
            profileService: profileService,
            authSessionService: authSessionService
        )

        await sut.handleTapLogout()

        XCTAssertEqual(router.presentedErrors.count, 1)
        XCTAssertGreaterThanOrEqual(presenter.presentedData.count, 2)
        XCTAssertEqual(presenter.presentedData[0].isLoggingOut, true)
        XCTAssertEqual(presenter.presentedData[1].isLoggingOut, false)
        let logoutCallsCount = await authSessionService.currentLogoutFromBackendCallsCount()
        XCTAssertEqual(logoutCallsCount, 1)
    }
}

extension ProfileInteractorTests {
    func testHandleTapCurrencyWhenProfileLoadedOpensCurrencySelection() async {
        let presenter = ProfilePresenterSpy()
        let router = ProfileRouterSpy()
        let profileService = ProfileServiceStub(
            results: [
                .success(
                    .init(
                        id: "user-1",
                        email: "sarah@example.com",
                        name: "Sarah Connor",
                        currency: "KZT",
                        preferredLanguage: "en-US",
                        tier: "ACTIVE",
                        tierValidUntil: nil
                    )
                )
            ]
        )
        let sut = makeSut(
            presenter: presenter,
            router: router,
            profileService: profileService
        )

        await sut.fetchData()
        await sut.handleTapCurrency()

        XCTAssertEqual(router.openCurrencySelectionCallsCount, 1)
        XCTAssertEqual(router.lastOpenedCurrencyCode, "KZT")
    }
}

extension ProfileInteractorTests {
    func testHandleTapSaveCurrencyPostsCurrencyChangedNotificationAndPersistsProfile() async {
        let presenter = ProfilePresenterSpy()
        let router = ProfileRouterSpy()
        let profileService = ProfileServiceStub(
            results: [
                .success(
                    .init(
                        id: "user-1",
                        email: "sarah@example.com",
                        name: "Sarah Connor",
                        currency: "USD",
                        preferredLanguage: "en-US",
                        tier: "ACTIVE",
                        tierValidUntil: nil
                    )
                )
            ],
            updateResults: [
                .success(
                    .init(
                        id: "user-1",
                        email: "sarah@example.com",
                        name: "Sarah Connor",
                        currency: "EUR",
                        preferredLanguage: "en-US",
                        tier: "ACTIVE",
                        tierValidUntil: nil
                    )
                )
            ]
        )
        let localProfileStorage = UserProfileStorageServiceSpy(
            storedProfile: .init(
                userId: "user-1",
                email: "sarah@example.com",
                name: "Sarah Connor",
                currency: "USD",
                language: "en-US",
                currencyRate: 1
            )
        )
        let sut = makeSut(
            presenter: presenter,
            router: router,
            profileService: profileService,
            localProfileStorage: localProfileStorage
        )

        let expectation = expectation(description: "Currency changed notification")
        var receivedPayload: ProfileCurrencyDidChangePayload?
        let token = NotificationCenter.default.addObserver(
            forName: .profileCurrencyDidChange,
            object: nil,
            queue: nil
        ) { notification in
            receivedPayload = notification.object as? ProfileCurrencyDidChangePayload
            expectation.fulfill()
        }
        defer {
            NotificationCenter.default.removeObserver(token)
        }

        await sut.fetchData()
        await sut.handleDidSelectCurrency("EUR")
        await sut.handleTapSaveCurrency()

        await fulfillment(of: [expectation], timeout: 1.0)

        XCTAssertEqual(receivedPayload?.previousCurrencyCode, "USD")
        XCTAssertEqual(receivedPayload?.updatedCurrencyCode, "EUR")
        XCTAssertEqual(receivedPayload?.updatedRateToUsd, 1)
        XCTAssertEqual(localProfileStorage.loadProfile()?.currency, "EUR")
    }
}

private extension ProfileInteractorTests {
    enum LoadingStatusCase {
        case loading
        case loaded
        case failed
    }

    func makeSut(
        presenter: ProfilePresentationLogic,
        router: ProfileRoutingLogic,
        profileService: ProfileContractServicing,
        localProfileStorage: UserProfileStorageServiceProtocol = UserProfileStorageServiceSpy(),
        authSessionService: AuthSessionServiceProtocol = AuthSessionServiceSpy(logoutResult: .success(()))
    ) -> ProfileInteractor {
        ProfileInteractor(
            presenter: presenter,
            router: router,
            profileService: profileService,
            currencyRateService: CurrencyRateServiceStub(),
            userProfileStorageService: localProfileStorage,
            authSessionService: authSessionService
        )
    }

    func assertStatus(
        _ status: LoadingStatus,
        is expected: LoadingStatusCase,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        switch (status, expected) {
        case (.loading, .loading), (.loaded, .loaded), (.failed, .failed):
            XCTAssertTrue(true, file: file, line: line)
        default:
            XCTFail("Unexpected status", file: file, line: line)
        }
    }
}

@MainActor
private final class ProfilePresenterSpy: ProfilePresentationLogic {
    private(set) var presentedData: [ProfileFetchData] = []

    func presentFetchedData(_ data: ProfileFetchData) {
        presentedData.append(data)
    }
}

@MainActor
private final class ProfileRouterSpy: ProfileRoutingLogic {
    private(set) var openCurrencySelectionCallsCount = 0
    private(set) var lastOpenedCurrencyCode: String?
    private(set) var presentedErrors: [String] = []

    func openCurrencySelection(
        currentCurrencyCode: String,
        output: ProfileCurrencySelectionOutput
    ) {
        openCurrencySelectionCallsCount += 1
        lastOpenedCurrencyCode = currentCurrencyCode
    }

    func presentError(with text: String) {
        presentedErrors.append(text)
    }
}

private actor AuthSessionServiceSpy: AuthSessionServiceProtocol {
    private let logoutResult: Result<Void, Error>
    private var logoutFromBackendCallsCount = 0

    init(logoutResult: Result<Void, Error>) {
        self.logoutResult = logoutResult
    }

    func hasValidSession() async -> Bool {
        false
    }

    func refreshAccessToken() async throws -> AuthTokenDTO {
        throw StubError.any
    }

    func accessToken() async -> String? {
        nil
    }

    func logoutFromBackend() async throws {
        logoutFromBackendCallsCount += 1

        switch logoutResult {
        case .success:
            return
        case let .failure(error):
            throw error
        }
    }

    func logout() async {}

    func currentLogoutFromBackendCallsCount() -> Int {
        logoutFromBackendCallsCount
    }
}

private actor ProfileServiceStub: ProfileContractServicing {
    private var results: [Result<ProfileResponseDTO, Error>]
    private let updateResults: [Result<ProfileResponseDTO, Error>]
    private var getProfileCallsCount = 0
    private var updateProfileCallsCount = 0

    init(
        results: [Result<ProfileResponseDTO, Error>],
        updateResults: [Result<ProfileResponseDTO, Error>] = [.failure(StubError.any)]
    ) {
        self.results = results
        self.updateResults = updateResults
    }

    func getProfile() async throws -> ProfileResponseDTO {
        getProfileCallsCount += 1

        guard !results.isEmpty else {
            throw StubError.any
        }

        let result = results.removeFirst()
        return try result.get()
    }

    func updateProfile(_ request: ProfileUpdateRequestDTO) async throws -> ProfileResponseDTO {
        let index = min(updateProfileCallsCount, max(updateResults.count - 1, .zero))
        updateProfileCallsCount += 1
        return try updateResults[index].get()
    }

    func callsCount() -> Int {
        getProfileCallsCount
    }
}

private struct CurrencyRateServiceStub: MainCurrencyRateContractServicing {
    func getCurrencyRate(currency: String) async throws -> CurrencyRateResponseDTO {
        .init(currency: currency, rateToUsd: 1, asOf: "")
    }
}

private final class UserProfileStorageServiceSpy: UserProfileStorageServiceProtocol, @unchecked Sendable {
    private var storedProfile: UserProfileDefaults?

    init(storedProfile: UserProfileDefaults? = nil) {
        self.storedProfile = storedProfile
    }

    func saveProfile(_ profile: UserProfileDefaults) {
        storedProfile = profile
    }

    func loadProfile() -> UserProfileDefaults? {
        storedProfile
    }

    func clearProfile() {}
}

private enum StubError: Error {
    case any
}
