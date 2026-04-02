import XCTest
@testable import Vault

@MainActor
final class ProfilePresenterTests: XCTestCase {
    private var sut: ProfilePresenter!
    private var handler: ProfileHandlerSpy!

    override func setUp() {
        super.setUp()
        handler = ProfileHandlerSpy()
        sut = ProfilePresenter(viewModel: .init())
        sut.handler = handler
    }

    override func tearDown() {
        handler = nil
        sut = nil
        super.tearDown()
    }
}

extension ProfilePresenterTests {
    func testPresentFetchedDataLoadingBuildsLoadingState() {
        sut.presentFetchedData(
            ProfileFetchData(
                loadingState: .loading,
                appVersion: "2.4.0",
                appBuild: "302"
            )
        )

        XCTAssertEqual(sut.viewModel.navigationTitle.text, L10n.profileSettingsTitle)

        guard case let .loading(content) = sut.viewModel.state else {
            return XCTFail("Expected loading state")
        }

        XCTAssertEqual(content.generalSectionTitle.text, L10n.profileGeneral)
        XCTAssertEqual(content.rows.count, 2)
        XCTAssertEqual(content.logoutButton.title, L10n.profileLogout)
        XCTAssertEqual(content.version.text, L10n.profileVersion("2.4.0", "302"))
    }
}

extension ProfilePresenterTests {
    func testPresentFetchedDataLoadedMapsProfileContent() {
        sut.presentFetchedData(
            ProfileFetchData(
                loadingState: .loaded,
                profile: .init(
                    id: "user-1",
                    email: "sarah@example.com",
                    name: "Sarah Connor",
                    currency: "GBP",
                    preferredLanguage: "en-GB",
                    tier: "PREMIUM_ACTIVE",
                    tierValidUntil: Date(timeIntervalSince1970: 1_775_001_600)
                ),
                appVersion: "2.4.0",
                appBuild: "302"
            )
        )

        guard case let .loaded(content) = sut.viewModel.state else {
            return XCTFail("Expected loaded state")
        }

        XCTAssertEqual(content.avatar.initials.text, "SC")
        XCTAssertEqual(content.name.text, "Sarah Connor")
        XCTAssertEqual(content.membership.text, L10n.profileMemberStatus("Premium Active"))
        XCTAssertEqual(content.plan.title.text, "Premium Active")
        XCTAssertEqual(content.rows.count, 2)
        XCTAssertEqual(content.rows[0].title.text, L10n.profileCurrency)
        XCTAssertTrue(content.rows[0].subtitle.text.contains("GBP"))
        XCTAssertEqual(content.rows[1].title.text, L10n.profileLanguage)
        XCTAssertFalse(content.rows[1].subtitle.text.isEmpty)
        XCTAssertEqual(content.version.text, L10n.profileVersion("2.4.0", "302"))
    }
}

extension ProfilePresenterTests {
    func testPresentFetchedDataFailedBuildsRetryErrorState() async {
        let retryExpectation = expectation(description: "Retry command")
        handler.onHandleRetry = {
            retryExpectation.fulfill()
        }

        sut.presentFetchedData(
            ProfileFetchData(
                loadingState: .failed(.undelinedError(description: "network failed"))
            )
        )

        guard case let .error(errorViewModel) = sut.viewModel.state else {
            return XCTFail("Expected error state")
        }

        XCTAssertEqual(errorViewModel.title.text, L10n.profileError)

        errorViewModel.tapCommand.execute()
        await fulfillment(of: [retryExpectation], timeout: 1.0)
    }
}

private final class ProfileHandlerSpy: ProfileHandler, @unchecked Sendable {
    var onHandleRetry: (() -> Void)?
    var onHandleLogout: (() -> Void)?
    var onHandleTapCurrency: (() -> Void)?
    var onHandleTapSaveCurrency: (() -> Void)?

    func handleTapRetry() async {
        onHandleRetry?()
    }

    func handleTapLogout() async {
        onHandleLogout?()
    }

    func handleTapCurrency() async {
        onHandleTapCurrency?()
    }

    func handleTapSaveCurrency() async {
        onHandleTapSaveCurrency?()
    }
}
