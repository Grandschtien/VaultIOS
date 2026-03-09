//
//  LayoutScaleProvider.swift
//  Vault
//
//  Created by Codex on 09.03.2026.
//

import UIKit

protocol LayoutScaleProviding {
    var spaces: [CGFloat] { get }
    var sizes: [CGFloat] { get }
}

struct PowerOfTwoLayoutScaleProvider: LayoutScaleProviding {
    let spaces: [CGFloat]
    let sizes: [CGFloat]

    init() {
        spaces = Self.makePowerOfTwoScale(minimum: 2, maximum: 64)
        sizes = Self.makePowerOfTwoScale(minimum: 8, maximum: 128)
    }

    private static func makePowerOfTwoScale(minimum: Int, maximum: Int) -> [CGFloat] {
        guard minimum > 0, maximum >= minimum else { return [] }

        var values: [CGFloat] = []
        var current = minimum

        while current <= maximum {
            values.append(CGFloat(current))
            current *= 2
        }

        return values
    }
}
