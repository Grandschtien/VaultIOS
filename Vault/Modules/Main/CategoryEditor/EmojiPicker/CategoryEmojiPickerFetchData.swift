import Foundation

struct CategoryEmojiPickerFetchData: Sendable {
    let searchQuery: String
    let selectedEmoji: String
    let emojis: [CategoryEditorEmojiCatalogItem]

    init(
        searchQuery: String = "",
        selectedEmoji: String = "",
        emojis: [CategoryEditorEmojiCatalogItem] = []
    ) {
        self.searchQuery = searchQuery
        self.selectedEmoji = selectedEmoji
        self.emojis = emojis
    }
}
