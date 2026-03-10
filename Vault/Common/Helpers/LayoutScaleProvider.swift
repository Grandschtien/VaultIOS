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

extension LayoutScaleProviding {
    static var sizeXS: CGFloat { 8 }
    static var sizeS: CGFloat { 16 }
    static var sizeM: CGFloat { 32 }
    static var sizeL: CGFloat { 64 }
    
    static var spaceXXXS: CGFloat { 2 }
    static var spaceXXS: CGFloat { 4 }
    static var spaceXS: CGFloat { 8 }
    static var spaceS: CGFloat { 16 }
    static var spaceM: CGFloat { 32 }
    static var spaceL: CGFloat { 64 }
}
