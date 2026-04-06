import Foundation

protocol CategoryEmojiPickerBusinessLogic: Sendable {
    func fetchData() async
}

protocol CategoryEmojiPickerOutput: AnyObject, Sendable {
    func handleDidSelectEmoji(_ emoji: String) async
}

protocol CategoryEmojiPickerHandler: AnyObject, Sendable {
    func handleChangeSearchQuery(_ query: String) async
    func handleTapEmoji(_ emoji: String) async
    func handleTapClose() async
}

actor CategoryEmojiPickerInteractor: CategoryEmojiPickerBusinessLogic {
    private let presenter: CategoryEmojiPickerPresentationLogic
    private let router: CategoryEmojiPickerRoutingLogic
    private let output: CategoryEmojiPickerOutput
    private let presetProvider: CategoryEditorPresetProviding

    private var searchQuery: String
    private var selectedEmoji: String

    init(
        selectedEmoji: String,
        presenter: CategoryEmojiPickerPresentationLogic,
        router: CategoryEmojiPickerRoutingLogic,
        output: CategoryEmojiPickerOutput,
        presetProvider: CategoryEditorPresetProviding
    ) {
        self.searchQuery = ""
        self.selectedEmoji = selectedEmoji
        self.presenter = presenter
        self.router = router
        self.output = output
        self.presetProvider = presetProvider
    }

    func fetchData() async {
        await presentFetchedData()
    }
}

private extension CategoryEmojiPickerInteractor {
    func presentFetchedData() async {
        await presenter.presentFetchedData(
            CategoryEmojiPickerFetchData(
                searchQuery: searchQuery,
                selectedEmoji: selectedEmoji,
                emojis: filteredEmojis()
            )
        )
    }

    func filteredEmojis() -> [CategoryEditorEmojiCatalogItem] {
        let query = searchQuery
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard !query.isEmpty else {
            return presetProvider.emojiCatalog()
        }

        return presetProvider.emojiCatalog().filter { item in
            item.emoji.contains(query)
                || item.searchTokens.contains(where: { $0.contains(query) })
        }
    }
}

extension CategoryEmojiPickerInteractor: CategoryEmojiPickerHandler {
    func handleChangeSearchQuery(_ query: String) async {
        searchQuery = query
        await presentFetchedData()
    }

    func handleTapEmoji(_ emoji: String) async {
        selectedEmoji = emoji
        await output.handleDidSelectEmoji(emoji)
        await router.close()
    }

    func handleTapClose() async {
        await router.close()
    }
}
