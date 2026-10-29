import XCTest
@testable import Vylok

final class SubscriptionToastMessageSanitizerTests: XCTestCase {}

// MARK: - sanitize

extension SubscriptionToastMessageSanitizerTests {
    func testSanitizeWhenTextHasEnvironmentSuffixStripsIt() {
        // Act
        let result = SubscriptionToastMessageSanitizer.sanitize("Purchase successful [Environment: Xcode]")

        // Assert
        XCTAssertEqual(result, "Purchase successful")
    }

    func testSanitizeWhenTextHasNoEnvironmentSuffixKeepsIt() {
        // Act
        let result = SubscriptionToastMessageSanitizer.sanitize("Unable to verify purchase")

        // Assert
        XCTAssertEqual(result, "Unable to verify purchase")
    }
}
