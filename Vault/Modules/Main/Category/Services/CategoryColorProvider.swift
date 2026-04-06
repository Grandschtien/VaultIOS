// Created by Egor Shkarin on 28.03.2026

import UIKit

protocol CategoryColorProviding: Sendable {
    func color(for value: String) -> UIColor
    func summaryColor(for value: String) -> UIColor
    func accentColor(for value: String) -> UIColor
    func normalizedHex(from value: String) -> String?
    func hexString(from color: UIColor) -> String?
}

final class CategoryColorProvider: CategoryColorProviding, @unchecked Sendable {
    private let legacyColorValues: Set<String> = [
        "light_red",
        "light_orange",
        "light_green",
        "light_blue",
        "light_purple",
        "light_pink"
    ]

    func color(for value: String) -> UIColor {
        if let hexColor = UIColor(hex: value) {
            return hexColor
        }

        switch value.lowercased() {
        case "light_red", "light_orange":
            return UIColor(red: 1.0, green: 0.93, blue: 0.84, alpha: 1)
        case "light_green":
            return UIColor(red: 0.89, green: 0.98, blue: 0.89, alpha: 1)
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

    func summaryColor(for value: String) -> UIColor {
        color(for: value)
    }

    func accentColor(for value: String) -> UIColor {
        if let hexColor = UIColor(hex: value) {
            return hexColor
        }

        switch value.lowercased() {
        case "light_red", "light_orange":
            return .systemOrange
        case "light_green":
            return .systemGreen
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

    func normalizedHex(from value: String) -> String? {
        if let hexColor = UIColor(hex: value) {
            return hexString(from: hexColor)
        }

        let normalizedValue = value.lowercased()
        guard legacyColorValues.contains(normalizedValue) else {
            return nil
        }

        return hexString(from: color(for: normalizedValue))
    }

    func hexString(from color: UIColor) -> String? {
        color.hexString
    }
}

private extension UIColor {
    convenience init?(
        hex: String
    ) {
        let normalized = hex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        guard normalized.count == 6,
              let value = Int(normalized, radix: 16)
        else {
            return nil
        }

        let red = CGFloat((value >> 16) & 0xFF) / 255
        let green = CGFloat((value >> 8) & 0xFF) / 255
        let blue = CGFloat(value & 0xFF) / 255

        self.init(red: red, green: green, blue: blue, alpha: 1)
    }

    var hexString: String? {
        var red: CGFloat = .zero
        var green: CGFloat = .zero
        var blue: CGFloat = .zero
        var alpha: CGFloat = .zero

        guard getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return nil
        }

        let redValue = Int(round(red * 255))
        let greenValue = Int(round(green * 255))
        let blueValue = Int(round(blue * 255))

        return String(format: "#%02X%02X%02X", redValue, greenValue, blueValue)
    }
}
