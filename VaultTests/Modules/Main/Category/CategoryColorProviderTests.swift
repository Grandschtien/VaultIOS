import XCTest
import UIKit
@testable import Vault

final class CategoryColorProviderTests: XCTestCase {
    private var sut: CategoryColorProvider!

    override func setUp() {
        super.setUp()
        sut = CategoryColorProvider()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }
}

extension CategoryColorProviderTests {
    func testSummaryColorMappingReturnsExpectedPalette() {
        assertColor(
            sut.summaryColor(for: "light_red"),
            equals: UIColor(red: 1.0, green: 0.93, blue: 0.84, alpha: 1)
        )
        assertColor(
            sut.summaryColor(for: "light_blue"),
            equals: UIColor(red: 0.86, green: 0.92, blue: 0.99, alpha: 1)
        )
        assertColor(
            sut.summaryColor(for: "light_purple"),
            equals: UIColor(red: 0.91, green: 0.84, blue: 1.0, alpha: 1)
        )
        assertColor(
            sut.summaryColor(for: "light_pink"),
            equals: UIColor(red: 0.99, green: 0.91, blue: 0.95, alpha: 1)
        )
    }
}

extension CategoryColorProviderTests {
    func testSummaryColorUnknownUsesDefaultColor() {
        assertColor(
            sut.summaryColor(for: "unknown"),
            equals: Asset.Colors.interactiveInputBackground.color
        )
    }

    func testAccentColorMappingReturnsExpectedPalette() {
        assertColor(sut.accentColor(for: "light_orange"), equals: .systemOrange)
        assertColor(sut.accentColor(for: "light_blue"), equals: .systemBlue)
        assertColor(sut.accentColor(for: "light_purple"), equals: .systemPurple)
        assertColor(sut.accentColor(for: "light_pink"), equals: .systemPink)
        assertColor(
            sut.accentColor(for: "unknown"),
            equals: Asset.Colors.interactiveElemetsPrimary.color
        )
    }

    func testNormalizedHexMapsLegacyPaletteValue() {
        XCTAssertEqual(sut.normalizedHex(from: "light_blue"), "#DBEBFC")
    }

    func testNormalizedHexKeepsHexValueUppercased() {
        XCTAssertEqual(sut.normalizedHex(from: "#a0e7e5"), "#A0E7E5")
    }

    func testNormalizedHexReturnsNilForUnknownValue() {
        XCTAssertNil(sut.normalizedHex(from: "unknown"))
    }
}

private extension CategoryColorProviderTests {
    func assertColor(
        _ lhs: UIColor,
        equals rhs: UIColor,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let lhsComponents = lhs.rgbaComponents,
              let rhsComponents = rhs.rgbaComponents else {
            return XCTFail("Unable to extract color components", file: file, line: line)
        }

        XCTAssertEqual(lhsComponents.r, rhsComponents.r, accuracy: 0.01, file: file, line: line)
        XCTAssertEqual(lhsComponents.g, rhsComponents.g, accuracy: 0.01, file: file, line: line)
        XCTAssertEqual(lhsComponents.b, rhsComponents.b, accuracy: 0.01, file: file, line: line)
        XCTAssertEqual(lhsComponents.a, rhsComponents.a, accuracy: 0.01, file: file, line: line)
    }
}

private extension UIColor {
    var rgbaComponents: (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat)? {
        var red: CGFloat = .zero
        var green: CGFloat = .zero
        var blue: CGFloat = .zero
        var alpha: CGFloat = .zero

        guard getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return nil
        }

        return (red, green, blue, alpha)
    }
}
