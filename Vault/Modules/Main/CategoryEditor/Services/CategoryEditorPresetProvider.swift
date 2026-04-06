import Foundation

protocol CategoryEditorPresetProviding: Sendable {
    var defaultEmoji: String { get }
    var defaultColorHex: String { get }
    func emojiPresets() -> [String]
    func colorPresets() -> [String]
    func emojiCatalog() -> [CategoryEditorEmojiCatalogItem]
}

final class CategoryEditorPresetProvider: CategoryEditorPresetProviding {
    private enum Constants {
        static let emojiCatalog: [CategoryEditorEmojiCatalogItem] = [
            .init(emoji: "🍽️", searchTokens: ["food", "dining", "restaurant", "meal"]),
            .init(emoji: "🚗", searchTokens: ["car", "transport", "taxi", "travel"]),
            .init(emoji: "🛍️", searchTokens: ["shopping", "store", "bag", "retail"]),
            .init(emoji: "🎬", searchTokens: ["movie", "cinema", "entertainment", "film"]),
            .init(emoji: "🏠", searchTokens: ["home", "house", "rent", "utilities"]),
            .init(emoji: "💊", searchTokens: ["health", "medical", "medicine", "doctor"]),
            .init(emoji: "💵", searchTokens: ["cash", "money", "salary", "income"]),
            .init(emoji: "🎁", searchTokens: ["gift", "present", "celebration"]),
            .init(emoji: "☕️", searchTokens: ["coffee", "cafe", "drink"]),
            .init(emoji: "🧾", searchTokens: ["bill", "invoice", "receipt"]),
            .init(emoji: "✈️", searchTokens: ["flight", "travel", "vacation", "trip"]),
            .init(emoji: "📚", searchTokens: ["education", "books", "study"]),
            .init(emoji: "🐶", searchTokens: ["pets", "dog", "cat", "animal"]),
            .init(emoji: "🏋️", searchTokens: ["fitness", "gym", "sport", "workout"]),
            .init(emoji: "🎮", searchTokens: ["games", "gaming", "console"]),
            .init(emoji: "💡", searchTokens: ["ideas", "electricity", "light"])
        ]

        static let colorPresets = [
            "#FFE6A7",
            "#FFD6A5",
            "#FDFFB6",
            "#CAFFBF",
            "#A0E7E5",
            "#BDE0FE",
            "#FFC6FF"
        ]
    }

    var defaultEmoji: String {
        emojiPresets().first ?? "🍽️"
    }

    var defaultColorHex: String {
        colorPresets().first ?? "#FFE6A7"
    }

    func emojiPresets() -> [String] {
        Array(Constants.emojiCatalog.prefix(7).map(\.emoji))
    }

    func colorPresets() -> [String] {
        Constants.colorPresets
    }

    func emojiCatalog() -> [CategoryEditorEmojiCatalogItem] {
        Constants.emojiCatalog
    }
}
