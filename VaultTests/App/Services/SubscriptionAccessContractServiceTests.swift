import XCTest
@testable import Vault

final class SubscriptionAccessContractServiceTests: XCTestCase {
    func testGetSubscriptionForwardsTargetAndDecodesResponse() async throws {
        let spy = AsyncNetworkClientContractSpy()
        spy.setResponse(
            json: #"{"tier":"PREMIUM","status":"active","paid_access_until":"2026-06-30T23:59:59Z","capabilities":["analytics","custom_date_range","ai_input"],"usage_limits":{"ai_requests":{"limit":300,"remaining":273}},"status_version":42}"#
        )

        var didCallGet = false
        spy.onRequest = { target in
            guard let api = target as? SubscriptionAccessAPI,
                  case .get = api else {
                return XCTFail("Expected SubscriptionAccessAPI.get")
            }

            didCallGet = true
        }

        let sut = SubscriptionAccessContractService(networkClient: spy)
        let response = try await sut.getSubscription()

        XCTAssertTrue(didCallGet)
        XCTAssertEqual(response.tier, .premium)
        XCTAssertEqual(response.status, .active)
        XCTAssertEqual(
            response.paidAccessUntil,
            Date(timeIntervalSince1970: 1_782_870_399)
        )
        XCTAssertEqual(
            response.capabilities,
            [.analytics, .customDateRange, .aiInput]
        )
        XCTAssertEqual(response.aiRequestsLimit, 300)
        XCTAssertEqual(response.aiRequestsRemaining, 273)
        XCTAssertEqual(response.statusVersion, 42)
        XCTAssertTrue(response.hasAnalyticsAccess)
        XCTAssertTrue(response.hasCustomDateRangeAccess)
        XCTAssertTrue(response.hasAiInputAccess)
    }
}

extension SubscriptionAccessContractServiceTests {
    func testGetSubscriptionDoesNotReuseSessionCacheBetweenCalls() async throws {
        let spy = AsyncNetworkClientContractSpy()
        spy.setResponse(
            json: #"{"tier":"PREMIUM","status":"active","paid_access_until":"2026-06-30T23:59:59Z","capabilities":["analytics"],"usage_limits":{"ai_requests":{"limit":300,"remaining":273}},"status_version":42}"#
        )

        let sut = SubscriptionAccessContractService(networkClient: spy)

        let firstResponse = try await sut.getSubscription()
        spy.setResponse(
            json: #"{"tier":"REGULAR","status":"expired","paid_access_until":null,"capabilities":[],"usage_limits":{"ai_requests":{"limit":0,"remaining":0}},"status_version":43}"#
        )
        let secondResponse = try await sut.getSubscription()

        XCTAssertEqual(firstResponse.tier, .premium)
        XCTAssertEqual(secondResponse.tier, .regular)
        XCTAssertEqual(spy.capturedTargets.count, 2)
    }

    func testRefreshSubscriptionLoadsLatestValue() async throws {
        let spy = AsyncNetworkClientContractSpy()
        let sut = SubscriptionAccessContractService(networkClient: spy)

        spy.setResponse(
            json: #"{"tier":"REGULAR","status":"expired","paid_access_until":null,"capabilities":[],"usage_limits":{"ai_requests":{"limit":0,"remaining":0}},"status_version":41}"#
        )
        let initialResponse = try await sut.getSubscription()

        spy.setResponse(
            json: #"{"tier":"PREMIUM","status":"active","paid_access_until":"2026-06-30T23:59:59Z","capabilities":["analytics","custom_date_range"],"usage_limits":{"ai_requests":{"limit":300,"remaining":120}},"status_version":42}"#
        )
        let refreshedResponse = try await sut.refreshSubscription()

        XCTAssertEqual(initialResponse.tier, .regular)
        XCTAssertEqual(refreshedResponse.tier, .premium)
        XCTAssertEqual(refreshedResponse.aiRequestsRemaining, 120)
        XCTAssertEqual(spy.capturedTargets.count, 2)
    }
}
