//
//  LayoutScaleProvider.swift
//  Vault
//
//  Created by Codex on 09.03.2026.
//

import UIKit

protocol LayoutScaleProviding {
    static var sizeXS: CGFloat { get }
    static var sizeS: CGFloat { get }
    static var sizeM: CGFloat { get }
    static var sizeL: CGFloat { get }

    static var spaceXXXS: CGFloat { get }
    static var spaceXXS: CGFloat { get }
    static var spaceXS: CGFloat { get }
    static var spaceS: CGFloat { get }
    static var spaceM: CGFloat { get }
    static var spaceL: CGFloat { get }
}

struct LayoutScale: LayoutScaleProviding {
    static let sizeXS: CGFloat = 8
    static let sizeS: CGFloat = 16
    static let sizeM: CGFloat = 32
    static let sizeL: CGFloat = 64

    static let spaceXXXS: CGFloat = 2
    static let spaceXXS: CGFloat = 4
    static let spaceXS: CGFloat = 8
    static let spaceS: CGFloat = 16
    static let spaceM: CGFloat = 32
    static let spaceL: CGFloat = 64
}
