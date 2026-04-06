import Foundation

struct CategoryEditorDraft: Equatable, Sendable {
    let name: String
    let emoji: String
    let colorHex: String
}

struct CategoryEditorEmojiCatalogItem: Equatable, Sendable {
    let emoji: String
    let searchTokens: [String]
}
