import XCTest
@testable import Vault

final class ProfileContractServiceTests: XCTestCase {
    func testGetProfileForwardsTargetAndDecodesResponse() async throws {
        let spy = AsyncNetworkClientContractSpy()
        spy.setResponse(
            json: #"{"id":"user-1","email":"jane@example.com","name":"Jane","currency":"USD","preferred_language":"en-US","tier":"REGULAR","tier_valid_until":null}"#
        )

        var didCallGet = false
        spy.onRequest = { target in
            guard let api = target as? ProfileAPI,
                  case .get = api else {
                return XCTFail("Expected ProfileAPI.get")
            }

            didCallGet = true
        }

        let sut = ProfileContractService(networkClient: spy)
        let response = try await sut.getProfile()

        XCTAssertTrue(didCallGet)
        XCTAssertEqual(response.id, "user-1")
        XCTAssertEqual(response.email, "jane@example.com")
        XCTAssertEqual(response.name, "Jane")
        XCTAssertEqual(response.currency, "USD")
        XCTAssertEqual(response.preferredLanguage, "en-US")
        XCTAssertEqual(response.tier, "REGULAR")
        XCTAssertNil(response.tierValidUntil)
    }
}

extension ProfileContractServiceTests {
    func testGetProfileUsesSessionCacheAfterFirstSuccessfulLoad() async throws {
        let spy = AsyncNetworkClientContractSpy()
        spy.setResponse(
            json: #"{"id":"user-1","email":"jane@example.com","name":"Jane","currency":"USD","preferred_language":"en-US","tier":"REGULAR","tier_valid_until":null}"#
        )

        let sut = ProfileContractService(networkClient: spy)

        let firstResponse = try await sut.getProfile()
        spy.nextError = StubError.any
        let cachedResponse = try await sut.getProfile()

        XCTAssertEqual(firstResponse, cachedResponse)
        XCTAssertEqual(spy.capturedTargets.count, 1)
    }

    func testRefreshProfileBypassesCacheAndReplacesCachedValue() async throws {
        let spy = AsyncNetworkClientContractSpy()
        let sut = ProfileContractService(networkClient: spy)

        spy.setResponse(
            json: #"{"id":"user-1","email":"jane@example.com","name":"Jane","currency":"USD","preferred_language":"en-US","tier":"REGULAR","tier_valid_until":null}"#
        )
        let initialResponse = try await sut.getProfile()

        spy.setResponse(
            json: #"{"id":"user-1","email":"jane@example.com","name":"Jane Doe","currency":"EUR","preferred_language":"en-US","tier":"ACTIVE","tier_valid_until":null}"#
        )
        let refreshedResponse = try await sut.refreshProfile()
        let cachedResponse = try await sut.getProfile()

        XCTAssertEqual(initialResponse.name, "Jane")
        XCTAssertEqual(refreshedResponse.name, "Jane Doe")
        XCTAssertEqual(refreshedResponse.currency, "EUR")
        XCTAssertEqual(cachedResponse, refreshedResponse)
        XCTAssertEqual(spy.capturedTargets.count, 2)
    }

    func testUpdateProfileUpdatesSessionCache() async throws {
        let spy = AsyncNetworkClientContractSpy()
        spy.setResponse(
            json: #"{"id":"user-1","email":"jane@example.com","name":"Jane Doe","currency":"EUR","preferred_language":"en-US","tier":"ACTIVE","tier_valid_until":null}"#
        )

        let sut = ProfileContractService(networkClient: spy)

        let updatedResponse = try await sut.updateProfile(
            .init(
                name: "Jane Doe",
                currency: "EUR",
                preferredLanguage: "en-US"
            )
        )
        spy.nextError = StubError.any
        let cachedResponse = try await sut.getProfile()

        XCTAssertEqual(updatedResponse, cachedResponse)
        XCTAssertEqual(spy.capturedTargets.count, 1)
    }

    func testLogoutNotificationClearsSessionCache() async throws {
        let spy = AsyncNetworkClientContractSpy()
        let sut = ProfileContractService(networkClient: spy)

        spy.setResponse(
            json: #"{"id":"user-1","email":"jane@example.com","name":"Jane","currency":"USD","preferred_language":"en-US","tier":"REGULAR","tier_valid_until":null}"#
        )
        _ = try await sut.getProfile()

        await MainActor.run {
            NotificationCenter.default.post(name: .authSessionDidLogout, object: nil)
        }
        await Task.yield()

        spy.setResponse(
            json: #"{"id":"user-1","email":"jane@example.com","name":"Jane Doe","currency":"EUR","preferred_language":"en-US","tier":"ACTIVE","tier_valid_until":null}"#
        )
        let refreshedResponse = try await sut.getProfile()

        XCTAssertEqual(refreshedResponse.name, "Jane Doe")
        XCTAssertEqual(spy.capturedTargets.count, 2)
    }
}

extension ProfileContractServiceTests {
    func testUpdateProfileForwardsPayloadAndDecodesResponse() async throws {
        let spy = AsyncNetworkClientContractSpy()
        spy.setResponse(
            json: #"{"id":"user-1","email":null,"name":"Jane Doe","currency":"EUR","preferred_language":"en-US","tier":"ACTIVE","tier_valid_until":"2026-04-01T00:00:00Z"}"#
        )

        var capturedRequest: ProfileUpdateRequestDTO?
        spy.onRequest = { target in
            guard let api = target as? ProfileAPI,
                  case let .update(request) = api else {
                return XCTFail("Expected ProfileAPI.update")
            }

            capturedRequest = request
        }

        let sut = ProfileContractService(networkClient: spy)
        let response = try await sut.updateProfile(
            .init(
                name: "Jane Doe",
                currency: "EUR",
                preferredLanguage: "en-US"
            )
        )

        XCTAssertEqual(capturedRequest?.name, "Jane Doe")
        XCTAssertEqual(capturedRequest?.currency, "EUR")
        XCTAssertEqual(capturedRequest?.preferredLanguage, "en-US")

        XCTAssertEqual(response.id, "user-1")
        XCTAssertNil(response.email)
        XCTAssertEqual(response.name, "Jane Doe")
        XCTAssertEqual(response.currency, "EUR")
        XCTAssertEqual(response.preferredLanguage, "en-US")
        XCTAssertEqual(response.tier, "ACTIVE")
        XCTAssertEqual(
            response.tierValidUntil,
            Date(timeIntervalSince1970: 1_775_001_600)
        )
    }
}

extension ProfileContractServiceTests {
    func testGetProfileWhenClientFailsRethrowsError() async {
        let spy = AsyncNetworkClientContractSpy()
        spy.nextError = StubError.any

        let sut = ProfileContractService(networkClient: spy)

        do {
            _ = try await sut.getProfile()
            XCTFail("Expected throw")
        } catch {
            XCTAssertNotNil(error as? StubError)
        }
    }

    func testGetProfileAfterFailureRequestsAgain() async throws {
        let spy = AsyncNetworkClientContractSpy()
        let sut = ProfileContractService(networkClient: spy)

        spy.nextError = StubError.any

        do {
            _ = try await sut.getProfile()
            XCTFail("Expected throw")
        } catch {
            XCTAssertNotNil(error as? StubError)
        }

        spy.nextError = nil
        spy.setResponse(
            json: #"{"id":"user-1","email":"jane@example.com","name":"Jane","currency":"USD","preferred_language":"en-US","tier":"REGULAR","tier_valid_until":null}"#
        )

        let response = try await sut.getProfile()

        XCTAssertEqual(response.name, "Jane")
        XCTAssertEqual(spy.capturedTargets.count, 2)
    }
}

private extension ProfileContractServiceTests {
    enum StubError: Error {
        case any
    }
}
