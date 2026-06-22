import SwiftUI
import UIKit

extension Font {
    static func appTypography(_ font: UIFont) -> Font {
        .system(
            size: font.pointSize,
            weight: fontWeight(for: font)
        )
    }

    private static func fontWeight(for font: UIFont) -> Font.Weight {
        let traits = font.fontDescriptor.object(
            forKey: .traits
        ) as? [UIFontDescriptor.TraitKey: Any]
        let value = (traits?[.weight] as? CGFloat) ?? UIFont.Weight.regular.rawValue

        switch value {
        case let value where value >= UIFont.Weight.bold.rawValue:
            return Font.Weight.bold
        case let value where value >= UIFont.Weight.semibold.rawValue:
            return Font.Weight.semibold
        case let value where value >= UIFont.Weight.medium.rawValue:
            return Font.Weight.medium
        case let value where value <= UIFont.Weight.light.rawValue:
            return Font.Weight.light
        default:
            return Font.Weight.regular
        }
    }
}
