//
//  Typography.swift
//  Vault
//
//  Created by Codex on 09.03.2026.
//

import UIKit

enum Typography {
    enum Weight: CaseIterable {
        case light
        case regular
        case medium
        case semibold
        case bold

        fileprivate var uiFontWeight: UIFont.Weight {
            switch self {
            case .light:
                return .light
            case .regular:
                return .regular
            case .medium:
                return .medium
            case .semibold:
                return .semibold
            case .bold:
                return .bold
            }
        }
    }

    static let minimumSize: CGFloat = 12
    static let maximumSize: CGFloat = 36
    static let step: CGFloat = 2

    static let supportedSizes: [CGFloat] = stride(from: maximumSize, through: minimumSize, by: -step).map { $0 }

    static func font(_ weight: Weight, size: CGFloat) -> UIFont {
        UIFont.systemFont(ofSize: normalizedSize(size), weight: weight.uiFontWeight)
    }

    static func light(size: CGFloat) -> UIFont {
        font(.light, size: size)
    }

    static func regular(size: CGFloat) -> UIFont {
        font(.regular, size: size)
    }

    static func medium(size: CGFloat) -> UIFont {
        font(.medium, size: size)
    }

    static func semibold(size: CGFloat) -> UIFont {
        font(.semibold, size: size)
    }

    static func bold(size: CGFloat) -> UIFont {
        font(.bold, size: size)
    }

    static let regular16: UIFont = regular(size: 16)
    static let medium16: UIFont = medium(size: 16)
    static let bold36: UIFont = bold(size: 36)

    // MARK: - Light

    static let typographyLight36: UIFont = light(size: 36)
    static let typographyLight34: UIFont = light(size: 34)
    static let typographyLight32: UIFont = light(size: 32)
    static let typographyLight30: UIFont = light(size: 30)
    static let typographyLight28: UIFont = light(size: 28)
    static let typographyLight26: UIFont = light(size: 26)
    static let typographyLight24: UIFont = light(size: 24)
    static let typographyLight22: UIFont = light(size: 22)
    static let typographyLight20: UIFont = light(size: 20)
    static let typographyLight18: UIFont = light(size: 18)
    static let typographyLight16: UIFont = light(size: 16)
    static let typographyLight14: UIFont = light(size: 14)
    static let typographyLight12: UIFont = light(size: 12)

    // MARK: - Regular

    static let typographyRegular36: UIFont = regular(size: 36)
    static let typographyRegular34: UIFont = regular(size: 34)
    static let typographyRegular32: UIFont = regular(size: 32)
    static let typographyRegular30: UIFont = regular(size: 30)
    static let typographyRegular28: UIFont = regular(size: 28)
    static let typographyRegular26: UIFont = regular(size: 26)
    static let typographyRegular24: UIFont = regular(size: 24)
    static let typographyRegular22: UIFont = regular(size: 22)
    static let typographyRegular20: UIFont = regular(size: 20)
    static let typographyRegular18: UIFont = regular(size: 18)
    static let typographyRegular16: UIFont = regular(size: 16)
    static let typographyRegular14: UIFont = regular(size: 14)
    static let typographyRegular12: UIFont = regular(size: 12)

    // MARK: - Medium

    static let typographyMedium36: UIFont = medium(size: 36)
    static let typographyMedium34: UIFont = medium(size: 34)
    static let typographyMedium32: UIFont = medium(size: 32)
    static let typographyMedium30: UIFont = medium(size: 30)
    static let typographyMedium28: UIFont = medium(size: 28)
    static let typographyMedium26: UIFont = medium(size: 26)
    static let typographyMedium24: UIFont = medium(size: 24)
    static let typographyMedium22: UIFont = medium(size: 22)
    static let typographyMedium20: UIFont = medium(size: 20)
    static let typographyMedium18: UIFont = medium(size: 18)
    static let typographyMedium16: UIFont = medium(size: 16)
    static let typographyMedium14: UIFont = medium(size: 14)
    static let typographyMedium12: UIFont = medium(size: 12)

    // MARK: - Semibold

    static let typographySemibold36: UIFont = semibold(size: 36)
    static let typographySemibold34: UIFont = semibold(size: 34)
    static let typographySemibold32: UIFont = semibold(size: 32)
    static let typographySemibold30: UIFont = semibold(size: 30)
    static let typographySemibold28: UIFont = semibold(size: 28)
    static let typographySemibold26: UIFont = semibold(size: 26)
    static let typographySemibold24: UIFont = semibold(size: 24)
    static let typographySemibold22: UIFont = semibold(size: 22)
    static let typographySemibold20: UIFont = semibold(size: 20)
    static let typographySemibold18: UIFont = semibold(size: 18)
    static let typographySemibold16: UIFont = semibold(size: 16)
    static let typographySemibold14: UIFont = semibold(size: 14)
    static let typographySemibold12: UIFont = semibold(size: 12)

    // MARK: - Bold

    static let typographyBold36: UIFont = bold(size: 36)
    static let typographyBold34: UIFont = bold(size: 34)
    static let typographyBold32: UIFont = bold(size: 32)
    static let typographyBold30: UIFont = bold(size: 30)
    static let typographyBold28: UIFont = bold(size: 28)
    static let typographyBold26: UIFont = bold(size: 26)
    static let typographyBold24: UIFont = bold(size: 24)
    static let typographyBold22: UIFont = bold(size: 22)
    static let typographyBold20: UIFont = bold(size: 20)
    static let typographyBold18: UIFont = bold(size: 18)
    static let typographyBold16: UIFont = bold(size: 16)
    static let typographyBold14: UIFont = bold(size: 14)
    static let typographyBold12: UIFont = bold(size: 12)

    private static func normalizedSize(_ rawSize: CGFloat) -> CGFloat {
        let clamped = min(max(rawSize, minimumSize), maximumSize)
        let snapped = (clamped / step).rounded() * step
        return min(max(snapped, minimumSize), maximumSize)
    }
}
