import XCTest
@testable import Vylok

@MainActor
final class ProfileInteractorTests: XCTestCase {
    func testFetchDataSuccessPublishesLoadingThenLoaded() async {
        let presenter = ProfilePresentationLogicMock()
        let router = ProfileRoutingLogicMock()
        let profileService = Self.makeProfileService(
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
            profileService: profileService,
            subscriptionAccessService: Self.makeSubscriptionAccessService(
                refreshedSnapshotResult: .init(
                    tier: .premium,
                    status: .active,
                    paidAccessUntil: nil,
                    capabilities: [],
                    aiRequestsLimit: 0,
                    aiRequestsRemaining: 0,
                    statusVersion: 42
                )
            )
        )

        await sut.fetchData()

        guard let first = presenter.presentFetchedDataReceivedInvocations.first,
              let last = presenter.presentFetchedDataReceivedInvocations.last else {
            return XCTFail("Expected presenter updates")
        }

        assertStatus(first.loadingState, is: .loading)
        assertStatus(last.loadingState, is: .loaded)
        XCTAssertEqual(last.profile?.name, "Sarah Connor")

        let serviceCallsCount = profileService.getProfileCallsCount
        XCTAssertEqual(serviceCallsCount, 1)
    }

    func testFetchDataWithCachedProfilePresentsLoadedWithoutLoadingThenRefreshesSubscription() async {
        let presenter = ProfilePresentationLogicMock()
        let profileService = Self.makeProfileService(results: [])
        profileService.cachedProfileReturnValue = Self.makeCachedProfile()
        let subscriptionAccessService = Self.makeSubscriptionAccessService(
            currentTierResult: "REGULAR",
            refreshTierResult: "PREMIUM"
        )
        let sut = makeSut(
            presenter: presenter,
            router: ProfileRoutingLogicMock(),
            profileService: profileService,
            subscriptionAccessService: subscriptionAccessService
        )

        await sut.fetchData()

        let invocations = presenter.presentFetchedDataReceivedInvocations
        XCTAssertEqual(invocations.map(\.loadingState), [.loaded, .loaded])
        XCTAssertEqual(invocations.map { $0.subscription?.tier }, [.regular, .premium])
        XCTAssertEqual(invocations.first?.profile?.name, "Sarah Connor")
        XCTAssertEqual(profileService.getProfileCallsCount, 0)
        XCTAssertEqual(subscriptionAccessService.refreshCurrentSubscriptionSnapshotCallsCount, 1)
    }

    func testFetchDataWithCachedProfileDoesNotRepresentWhenRefreshedSubscriptionIsUnchanged() async {
        let presenter = ProfilePresentationLogicMock()
        let profileService = Self.makeProfileService(results: [])
        profileService.cachedProfileReturnValue = Self.makeCachedProfile()
        let sut = makeSut(
            presenter: presenter,
            router: ProfileRoutingLogicMock(),
            profileService: profileService,
            subscriptionAccessService: Self.makeSubscriptionAccessService(
                currentTierResult: "REGULAR",
                refreshTierResult: "REGULAR"
            )
        )

        await sut.fetchData()

        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.map(\.loadingState), [.loaded])
    }

    nonisolated static func makeCachedProfile() -> ProfileResponseDTO {
        .init(
            id: "user-1",
            email: "sarah@example.com",
            name: "Sarah Connor",
            currency: "USD",
            preferredLanguage: "en-US",
            tier: "REGULAR",
            tierValidUntil: nil
        )
    }
}

extension ProfileInteractorTests {
    func testSubscriptionAccessDidChangeUpdatesPresentedUsageWithoutRefetchingProfile() async {
        let notificationCenter = NotificationCenter()
        let presenter = ProfilePresentationLogicMock()
        let router = ProfileRoutingLogicMock()
        let profileService = Self.makeProfileService(
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
        let initialSnapshot = SubscriptionAccessSnapshot(
            tier: .premium,
            status: .active,
            paidAccessUntil: nil,
            capabilities: [.analytics, .customDateRange, .aiInput],
            aiRequestsLimit: 300,
            aiRequestsRemaining: 273,
            statusVersion: 42
        )
        let sut = makeSut(
            presenter: presenter,
            router: router,
            profileService: profileService,
            subscriptionAccessService: Self.makeSubscriptionAccessService(
                refreshedSnapshotResult: initialSnapshot
            ),
            notificationCenter: notificationCenter
        )

        await sut.fetchData()

        let updatedSnapshot = SubscriptionAccessSnapshot(
            tier: .premium,
            status: .active,
            paidAccessUntil: nil,
            capabilities: [.analytics, .customDateRange, .aiInput],
            aiRequestsLimit: 300,
            aiRequestsRemaining: 272,
            statusVersion: 42
        )

        let usageUpdated = presentationExpectation(on: presenter) { data in
            data.subscription?.aiRequestsRemaining == 272
        }

        notificationCenter.post(
            name: .subscriptionAccessDidChange,
            object: updatedSnapshot
        )
        await fulfillment(of: [usageUpdated], timeout: 1)

        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.subscription?.aiRequestsRemaining, 272)
        assertStatus(presenter.presentFetchedDataReceivedInvocations.last?.loadingState ?? .idle, is: .loaded)
        let serviceCallsCount = profileService.getProfileCallsCount
        XCTAssertEqual(serviceCallsCount, 1)
    }
}

extension ProfileInteractorTests {
    func testFetchDataInitialLoadingUsesCurrencyFromLocalProfileStorage() async {
        let presenter = ProfilePresentationLogicMock()
        let router = ProfileRoutingLogicMock()
        let profileService = Self.makeProfileService(
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
        let localProfileStorage = Self.makeProfileStorage(
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

        guard presenter.presentFetchedDataReceivedInvocations.count >= 2 else {
            return XCTFail("Expected loading and loaded presenter states")
        }

        let loadingState = presenter.presentFetchedDataReceivedInvocations[0]
        let loadedState = presenter.presentFetchedDataReceivedInvocations[1]

        XCTAssertEqual(loadingState.selectedCurrencyCode, "KZT")
        XCTAssertEqual(loadedState.selectedCurrencyCode, "USD")
    }
}

extension ProfileInteractorTests {
    func testFetchDataFailurePublishesFailedState() async {
        let presenter = ProfilePresentationLogicMock()
        let router = ProfileRoutingLogicMock()
        let profileService = Self.makeProfileService(
            results: [.failure(StubError.any)]
        )
        let sut = makeSut(
            presenter: presenter,
            router: router,
            profileService: profileService
        )

        await sut.fetchData()

        guard let first = presenter.presentFetchedDataReceivedInvocations.first,
              let last = presenter.presentFetchedDataReceivedInvocations.last else {
            return XCTFail("Expected presenter updates")
        }

        assertStatus(first.loadingState, is: .loading)
        assertStatus(last.loadingState, is: .failed)

        let serviceCallsCount = profileService.getProfileCallsCount
        XCTAssertEqual(serviceCallsCount, 1)
    }
}

extension ProfileInteractorTests {
    func testHandleTapRetryRepeatsFetchFlow() async {
        let presenter = ProfilePresentationLogicMock()
        let router = ProfileRoutingLogicMock()
        let profileService = Self.makeProfileService(
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

        guard let last = presenter.presentFetchedDataReceivedInvocations.last else {
            return XCTFail("Expected presenter updates")
        }

        assertStatus(last.loadingState, is: .loaded)
        XCTAssertEqual(last.profile?.tier, "ACTIVE")

        let serviceCallsCount = profileService.getProfileCallsCount
        XCTAssertEqual(serviceCallsCount, 2)
    }
}

extension ProfileInteractorTests {
    func testHandleTapLogoutOpensConfirmationWithoutStartingLogout() async {
        let presenter = ProfilePresentationLogicMock()
        let router = ProfileRoutingLogicMock()
        let profileService = Self.makeProfileService(results: [])
        let authSessionService = Self.makeAuthSessionService(logoutResult: .success(()))
        let sut = makeSut(
            presenter: presenter,
            router: router,
            profileService: profileService,
            authSessionService: authSessionService
        )

        await sut.handleTapLogout()

        XCTAssertEqual(router.openConfirmationContextCallsCount, 1)
        XCTAssertEqual(router.openConfirmationContextReceivedInvocations.last?.title, L10n.profileLogoutConfirmationTitle)
        XCTAssertEqual(router.openConfirmationContextReceivedInvocations.last?.confirmButtonTitle, L10n.commonConfirm)
        XCTAssertEqual(router.openConfirmationContextReceivedInvocations.last?.cancelButtonTitle, L10n.commonCancel)
        XCTAssertTrue(router.presentErrorWithReceivedInvocations.isEmpty)
        let logoutCallsCount = authSessionService.logoutFromBackendCallsCount
        XCTAssertEqual(logoutCallsCount, 0)
        XCTAssertTrue(presenter.presentFetchedDataReceivedInvocations.isEmpty)
    }
}

extension ProfileInteractorTests {
    func testHandleTapLogoutConfirmWhenBackendRequestSucceedsDoesNotPresentError() async {
        let presenter = ProfilePresentationLogicMock()
        let router = ProfileRoutingLogicMock()
        let profileService = Self.makeProfileService(results: [])
        let authSessionService = Self.makeAuthSessionService(logoutResult: .success(()))
        let sut = makeSut(
            presenter: presenter,
            router: router,
            profileService: profileService,
            authSessionService: authSessionService
        )

        await sut.handleTapLogout()
        router.openConfirmationContextReceivedInvocations.last?.confirmCommand.execute()
        await waitForCommandExecution()

        XCTAssertTrue(router.presentErrorWithReceivedInvocations.isEmpty)
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.isLoggingOut, true)
        let logoutCallsCount = authSessionService.logoutFromBackendCallsCount
        XCTAssertEqual(logoutCallsCount, 1)
    }
}

extension ProfileInteractorTests {
    func testHandleTapLogoutConfirmWhenBackendRequestFailsPresentsErrorToast() async {
        let presenter = ProfilePresentationLogicMock()
        let router = ProfileRoutingLogicMock()
        let profileService = Self.makeProfileService(results: [])
        let authSessionService = Self.makeAuthSessionService(logoutResult: .failure(StubError.any))
        let sut = makeSut(
            presenter: presenter,
            router: router,
            profileService: profileService,
            authSessionService: authSessionService
        )

        await sut.handleTapLogout()
        router.openConfirmationContextReceivedInvocations.last?.confirmCommand.execute()
        await waitForCommandExecution()

        XCTAssertEqual(router.presentErrorWithReceivedInvocations.count, 1)
        XCTAssertGreaterThanOrEqual(presenter.presentFetchedDataReceivedInvocations.count, 2)
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations[0].isLoggingOut, true)
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations[1].isLoggingOut, false)
        let logoutCallsCount = authSessionService.logoutFromBackendCallsCount
        XCTAssertEqual(logoutCallsCount, 1)
    }
}

extension ProfileInteractorTests {
    func testHandleTapDeleteAccountOpensDestructiveConfirmationWithoutStartingDeletion() async {
        let presenter = ProfilePresentationLogicMock()
        let router = ProfileRoutingLogicMock()
        let profileService = Self.makeProfileService(results: [])
        let authSessionService = Self.makeAuthSessionService(logoutResult: .success(()))
        let sut = makeSut(
            presenter: presenter,
            router: router,
            profileService: profileService,
            authSessionService: authSessionService
        )

        await sut.handleTapDeleteAccount()

        XCTAssertEqual(router.openConfirmationContextCallsCount, 1)
        XCTAssertEqual(router.openConfirmationContextReceivedInvocations.last?.title, L10n.profileDeleteAccount)
        XCTAssertEqual(router.openConfirmationContextReceivedInvocations.last?.subtitle, L10n.profileDeleteAccountConfirmationTitle)
        XCTAssertEqual(router.openConfirmationContextReceivedInvocations.last?.confirmButtonTitle, L10n.profileDeleteAccount)
        XCTAssertEqual(router.openConfirmationContextReceivedInvocations.last?.confirmButtonStyle, .destructive)
        XCTAssertEqual(router.openConfirmationContextReceivedInvocations.last?.cancelButtonTitle, L10n.commonCancel)
        XCTAssertEqual(router.openConfirmationContextReceivedInvocations.last?.cancelButtonStyle, .primary)
        XCTAssertTrue(router.presentErrorWithReceivedInvocations.isEmpty)

        let deleteCallsCount = profileService.deleteAccountCallsCount
        let logoutCallsCount = authSessionService.logoutCallsCount
        XCTAssertEqual(deleteCallsCount, 0)
        XCTAssertEqual(logoutCallsCount, 0)
        XCTAssertTrue(presenter.presentFetchedDataReceivedInvocations.isEmpty)
    }
}

extension ProfileInteractorTests {
    func testHandleTapDeleteAccountConfirmWhenRequestSucceedsLogsOutLocally() async {
        let presenter = ProfilePresentationLogicMock()
        let router = ProfileRoutingLogicMock()
        let profileService = Self.makeProfileService(
            results: [],
            deleteAccountResult: .success(())
        )
        let authSessionService = Self.makeAuthSessionService(logoutResult: .success(()))
        let sut = makeSut(
            presenter: presenter,
            router: router,
            profileService: profileService,
            authSessionService: authSessionService
        )

        await sut.handleTapDeleteAccount()
        router.openConfirmationContextReceivedInvocations.last?.confirmCommand.execute()
        await waitForCommandExecution()

        XCTAssertTrue(router.presentErrorWithReceivedInvocations.isEmpty)

        let deleteCallsCount = profileService.deleteAccountCallsCount
        let logoutCallsCount = authSessionService.logoutCallsCount
        let logoutFromBackendCallsCount = authSessionService.logoutFromBackendCallsCount
        XCTAssertEqual(deleteCallsCount, 1)
        XCTAssertEqual(logoutCallsCount, 1)
        XCTAssertEqual(logoutFromBackendCallsCount, 0)
    }
}

extension ProfileInteractorTests {
    func testHandleTapDeleteAccountConfirmWhenRequestFailsPresentsErrorWithoutLogout() async {
        let presenter = ProfilePresentationLogicMock()
        let router = ProfileRoutingLogicMock()
        let profileService = Self.makeProfileService(
            results: [],
            deleteAccountResult: .failure(StubError.any)
        )
        let authSessionService = Self.makeAuthSessionService(logoutResult: .success(()))
        let sut = makeSut(
            presenter: presenter,
            router: router,
            profileService: profileService,
            authSessionService: authSessionService
        )

        await sut.handleTapDeleteAccount()
        router.openConfirmationContextReceivedInvocations.last?.confirmCommand.execute()
        await waitForCommandExecution()

        XCTAssertEqual(router.presentErrorWithReceivedInvocations.count, 1)

        let deleteCallsCount = profileService.deleteAccountCallsCount
        let logoutCallsCount = authSessionService.logoutCallsCount
        XCTAssertEqual(deleteCallsCount, 1)
        XCTAssertEqual(logoutCallsCount, 0)
    }
}

extension ProfileInteractorTests {
    func testHandleTapCurrencyWhenProfileLoadedOpensCurrencySelection() async {
        let presenter = ProfilePresentationLogicMock()
        let router = ProfileRoutingLogicMock()
        let profileService = Self.makeProfileService(
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

        XCTAssertEqual(router.openCurrencySelectionCurrentCurrencyCodeOutputCallsCount, 1)
        XCTAssertEqual(router.openCurrencySelectionCurrentCurrencyCodeOutputReceivedInvocations.last?.currentCurrencyCode, "KZT")
    }
}

extension ProfileInteractorTests {
    func testHandleTapSubscriptionWhenProfileLoadedOpensSubscription() async {
        let presenter = ProfilePresentationLogicMock()
        let router = ProfileRoutingLogicMock()
        let profileService = Self.makeProfileService(
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
        let sut = makeSut(
            presenter: presenter,
            router: router,
            profileService: profileService
        )

        await sut.fetchData()
        await sut.handleTapSubscription()

        XCTAssertEqual(router.openSubscriptionCurrentTierOutputCallsCount, 1)
        XCTAssertEqual(router.openSubscriptionCurrentTierOutputReceivedInvocations.last?.currentTier, .premium)
    }
}

extension ProfileInteractorTests {
    func testHandleSubscriptionDidSyncRefreshesTierAccessAndReloadsProfile() async {
        let presenter = ProfilePresentationLogicMock()
        let router = ProfileRoutingLogicMock()
        let profileService = Self.makeProfileService(
            results: [
                .success(
                    .init(
                        id: "user-1",
                        email: "sarah@example.com",
                        name: "Sarah Connor",
                        currency: "USD",
                        preferredLanguage: "en-US",
                        tier: "PLUS",
                        tierValidUntil: nil
                    )
                )
            ]
        )
        let subscriptionAccessService = Self.makeSubscriptionAccessService()
        let sut = makeSut(
            presenter: presenter,
            router: router,
            profileService: profileService,
            subscriptionAccessService: subscriptionAccessService
        )

        await sut.handleSubscriptionDidSync()

        let refreshCallsCount = (subscriptionAccessService.refreshCurrentSubscriptionSnapshotCallsCount + subscriptionAccessService.refreshCurrentTierStateCallsCount + subscriptionAccessService.refreshCurrentTierSourceStateCallsCount)
        let serviceCallsCount = profileService.getProfileCallsCount

        XCTAssertEqual(refreshCallsCount, 1)
        XCTAssertEqual(serviceCallsCount, 1)
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.profile?.tier, "PLUS")
        assertStatus(presenter.presentFetchedDataReceivedInvocations.last?.loadingState ?? .idle, is: .loaded)
    }
}

extension ProfileInteractorTests {
    func testHandleTapSaveCurrencyPostsCurrencyChangedNotificationAndPersistsProfile() async {
        let presenter = ProfilePresentationLogicMock()
        let router = ProfileRoutingLogicMock()
        let profileService = Self.makeProfileService(
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
        let localProfileStorage = Self.makeProfileStorage(
            storedProfile: .init(
                userId: "user-1",
                email: "sarah@example.com",
                name: "Sarah Connor",
                currency: "USD",
                language: "en-US",
                currencyRate: 1,
                cachedSubscription: .init(
                    tier: .premium,
                    status: .active,
                    paidAccessUntil: nil,
                    capabilities: [.analytics],
                    aiRequestsLimit: 300,
                    aiRequestsRemaining: 120,
                    statusVersion: 42
                )
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
        XCTAssertEqual(localProfileStorage.loadProfile()?.cachedSubscription?.tier, .premium)
    }
}

private extension ProfileInteractorTests {
    enum LoadingStatusCase {
        case loading
        case loaded
        case failed
    }

    func presentationExpectation(
        on presenter: ProfilePresentationLogicMock,
        where predicate: @escaping (ProfileFetchData) -> Bool
    ) -> XCTestExpectation {
        let expectation = expectation(description: "Presenter received expected data")
        expectation.assertForOverFulfill = false
        presenter.presentFetchedDataClosure = { data in
            guard predicate(data) else {
                return
            }

            expectation.fulfill()
        }
        return expectation
    }

    func makeSut(
        presenter: ProfilePresentationLogic,
        router: ProfileRoutingLogic,
        profileService: ProfileContractServicing,
        localProfileStorage: UserProfileStorageServiceProtocol = ProfileInteractorTests.makeProfileStorage(),
        authSessionService: AuthSessionServiceProtocol = ProfileInteractorTests.makeAuthSessionService(logoutResult: .success(())),
        subscriptionAccessService: SubscriptionAccessServicing = ProfileInteractorTests.makeSubscriptionAccessService(),
        notificationCenter: NotificationCenter = .default
    ) -> ProfileInteractor {
        ProfileInteractor(
            presenter: presenter,
            router: router,
            profileService: profileService,
            currencyRateService: Self.makeCurrencyRateService(),
            userProfileStorageService: localProfileStorage,
            authSessionService: authSessionService,
            subscriptionAccessService: subscriptionAccessService,
            applogSink: Self.makeAppLogSink(),
            notificationCenter: notificationCenter
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

    func waitForCommandExecution() async {
        for _ in 0..<10 {
            await Task.yield()
        }
    }
}

private enum StubError: Error {
    case any
}

private extension ProfileInteractorTests {
    nonisolated static func makeProfileService(
        results: [Result<ProfileResponseDTO, Error>],
        updateResults: [Result<ProfileResponseDTO, Error>] = [.failure(StubError.any)],
        deleteAccountResult: Result<Void, Error> = .success(())
    ) -> ProfileContractServicingMock {
        let profileService = ProfileContractServicingMock()
        profileService.getProfileClosure = { [unowned profileService] in
            let index = profileService.getProfileCallsCount - 1
            guard index < results.count else {
                throw StubError.any
            }

            return try results[index].get()
        }
        profileService.refreshProfileClosure = { [unowned profileService] in
            try await profileService.getProfile()
        }
        profileService.updateProfileClosure = { [unowned profileService] _ in
            let index = min(profileService.updateProfileCallsCount - 1, max(updateResults.count - 1, .zero))
            return try updateResults[index].get()
        }
        if case let .failure(error) = deleteAccountResult {
            profileService.deleteAccountThrowableError = error
        }
        return profileService
    }

    nonisolated static func makeAuthSessionService(logoutResult: Result<Void, Error>) -> AuthSessionServiceProtocolMock {
        let authSessionService = AuthSessionServiceProtocolMock()
        authSessionService.hasValidSessionReturnValue = false
        authSessionService.refreshAccessTokenThrowableError = StubError.any
        if case let .failure(error) = logoutResult {
            authSessionService.logoutFromBackendThrowableError = error
        }
        return authSessionService
    }

    nonisolated static func makeSubscriptionAccessService(
        currentTierResult: String = "REGULAR",
        refreshTierResult: String = "PLUS",
        currentSnapshotResult: SubscriptionAccessSnapshot? = nil,
        refreshedSnapshotResult: SubscriptionAccessSnapshot? = nil
    ) -> SubscriptionAccessServicingMock {
        let subscriptionAccessService = SubscriptionAccessServicingMock()
        subscriptionAccessService.currentTierStateReturnValue = .resolved(makeTier(from: currentTierResult))
        subscriptionAccessService.refreshCurrentTierStateReturnValue = .resolved(makeTier(from: refreshTierResult))
        subscriptionAccessService.refreshCurrentTierSourceStateReturnValue = .network(makeTier(from: refreshTierResult))
        subscriptionAccessService.currentSubscriptionSnapshotReturnValue = currentSnapshotResult
            ?? makeSnapshot(tier: currentTierResult)
        subscriptionAccessService.refreshCurrentSubscriptionSnapshotReturnValue = refreshedSnapshotResult
            ?? makeSnapshot(tier: refreshTierResult)
        return subscriptionAccessService
    }

    nonisolated static func makeProfileStorage(storedProfile: UserProfileDefaults? = nil) -> UserProfileStorageServiceProtocolMock {
        var currentProfile = storedProfile
        let profileStorage = UserProfileStorageServiceProtocolMock()
        profileStorage.loadProfileClosure = { currentProfile }
        profileStorage.saveProfileClosure = { currentProfile = $0 }
        return profileStorage
    }

    nonisolated static func makeCurrencyRateService() -> MainCurrencyRateContractServicingMock {
        let currencyRateService = MainCurrencyRateContractServicingMock()
        currencyRateService.getCurrencyRateCurrencyClosure = { .init(currency: $0, rateToUsd: 1, asOf: "") }
        return currencyRateService
    }

    nonisolated static func makeAppLogSink() -> AppLogSinkProtocolMock {
        let appLogSink = AppLogSinkProtocolMock()
        appLogSink.exportLogFileCompletionClosure = { completion in
            completion(.failure(StubError.any))
        }
        return appLogSink
    }

    nonisolated static func makeSnapshot(tier: String) -> SubscriptionAccessSnapshot? {
        guard !tier.isEmpty else {
            return nil
        }

        return SubscriptionAccessSnapshotFixtures.makeSnapshot(
            tier: makeTier(from: tier),
            capabilities: [],
            aiRequestsLimit: 0,
            aiRequestsRemaining: 0,
            statusVersion: 42,
            hasAiRequestsLimit: nil
        )
    }

    nonisolated static func makeTier(from rawTier: String) -> SubscriptionTier {
        rawTier == "REGULAR" ? .regular : .premium
    }
}
