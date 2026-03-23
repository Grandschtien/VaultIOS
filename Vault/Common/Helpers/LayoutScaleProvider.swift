//
//  LayoutScaleProvider.swift
//  Vault
//
//  Created by Egor Shkarin on 09.03.2026.
//

import UIKit

protocol LayoutScaleProviding {
    var sizeXS: CGFloat { get }
    var sizeS: CGFloat { get }
    var sizeM: CGFloat { get }
    var sizeL: CGFloat { get }
    var sizeXL: CGFloat { get }
    var sizeXXL: CGFloat { get }
    var sizeXXXL: CGFloat { get }

    var spaceXXXS: CGFloat { get }
    var spaceXXS: CGFloat { get }
    var spaceXS: CGFloat { get }
    var spaceS: CGFloat { get }
    var spaceM: CGFloat { get }
    var spaceL: CGFloat { get }
    var spaceXL: CGFloat { get }
}

extension LayoutScaleProviding {
    var sizeXS: CGFloat { 8 }
    var sizeS: CGFloat { 16 }
    var sizeM: CGFloat { 24 }
    var sizeL: CGFloat { 32 }
    var sizeXL: CGFloat { 64 }
    var sizeXXL: CGFloat { 128 }
    var sizeXXXL: CGFloat { 152 }

    var spaceXXXS: CGFloat { 2 }
    var spaceXXS: CGFloat { 4 }
    var spaceXS: CGFloat { 8 }
    var spaceS: CGFloat { 16 }
    var spaceM: CGFloat { 24 }
    var spaceL: CGFloat { 32 }
    var spaceXL: CGFloat { 64 }
}
