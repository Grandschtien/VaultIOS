import XCTest
@testable import Vault

final class SubscriptionContractServiceTests: XCTestCase {
    func testApprovePurchaseForwardsPayload() async throws {
        let spy = AsyncNetworkClientContractSpy()
        let request = SubscriptionApproveRequestDTO(
            signedTransactionInfo: "signed-transaction"
        )
        var capturedRequest: SubscriptionApproveRequestDTO?

        spy.onRequestWithoutResponse = { target in
            guard let api = target as? SubscriptionAPI,
                  case let .approve(payload) = api else {
                return XCTFail("Expected SubscriptionAPI.approve")
            }

            capturedRequest = payload
        }

        let sut = SubscriptionContractService(networkClient: spy)
        try await sut.approvePurchase(request)

        XCTAssertEqual(capturedRequest, request)
    }
}

extension SubscriptionContractServiceTests {
    func testApprovePurchaseWhenClientFailsRethrowsError() async {
        let spy = AsyncNetworkClientContractSpy()
        spy.nextError = StubError.any

        let sut = SubscriptionContractService(networkClient: spy)

        do {
            try await sut.approvePurchase(
                .init(
                    signedTransactionInfo: "signed-transaction"
                )
            )
            XCTFail("Expected throw")
        } catch {
            XCTAssertNotNil(error as? StubError)
        }
    }
}

private extension SubscriptionContractServiceTests {
    enum StubError: Error {
        case any
    }
}
