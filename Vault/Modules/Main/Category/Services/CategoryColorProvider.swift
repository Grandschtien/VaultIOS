// Created by Codex on 28.03.2026

import UIKit

protocol CategoryColorProviding: Sendable {
    func summaryColor(for value: String) -> UIColor
    func accentColor(for value: String) -> UIColor
}

final class CategoryColorProvider: CategoryColorProviding, @unchecked Sendable {
    func summaryColor(for value: String) -> UIColor {
        switch value {
        case "light_red", "light_orange":
            return UIColor(red: 1.0, green: 0.93, blue: 0.84, alpha: 1)
        case "light_blue":
            return UIColor(red: 0.86, green: 0.92, blue: 0.99, alpha: 1)
        case "light_purple":
            return UIColor(red: 0.91, green: 0.84, blue: 1.0, alpha: 1)
        case "light_pink":
            return UIColor(red: 0.99, green: 0.91, blue: 0.95, alpha: 1)
        default:
            return Asset.Colors.interactiveInputBackground.color
        }
    }

    func accentColor(for value: String) -> UIColor {
        switch value {
        case "light_red", "light_orange":
            return .systemOrange
        case "light_blue":
            return .systemBlue
        case "light_purple":
            return .systemPurple
        case "light_pink":
            return .systemPink
        default:
            return Asset.Colors.interactiveElemetsPrimary.color
        }
    }
}
