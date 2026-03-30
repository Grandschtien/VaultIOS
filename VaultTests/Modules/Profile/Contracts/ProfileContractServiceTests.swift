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
}

private extension ProfileContractServiceTests {
    enum StubError: Error {
        case any
    }
}
