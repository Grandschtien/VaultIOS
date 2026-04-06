import UIKit
internal import Combine

@MainActor
protocol CategoryEmojiPickerPresentationLogic: Sendable {
    func presentFetchedData(_ data: CategoryEmojiPickerFetchData)
}

final class CategoryEmojiPickerPresenter: CategoryEmojiPickerPresentationLogic {
    @Published
    private(set) var viewModel: CategoryEmojiPickerViewModel

    weak var handler: CategoryEmojiPickerHandler?

    init(viewModel: CategoryEmojiPickerViewModel) {
        self.viewModel = viewModel
    }

    func presentFetchedData(_ data: CategoryEmojiPickerFetchData) {
        let rows = data.emojis.map { item in
            CategoryEmojiPickerViewModel.RowViewModel(
                emoji: item.emoji,
                isSelected: data.selectedEmoji == item.emoji,
                tapCommand: Command { [weak handler] in
                    await handler?.handleTapEmoji(item.emoji)
                }
            )
        }

        viewModel = CategoryEmojiPickerViewModel(
            header: .init(
                title: .init(
                    text: L10n.categoryEmojiPickerTitle,
                    font: Typography.typographyBold20,
                    textColor: Asset.Colors.textAndIconPrimary.color,
                    alignment: .center
                ),
                closeCommand: Command { [weak handler] in
                    await handler?.handleTapClose()
                }
            ),
            searchField: .init(
                text: data.searchQuery,
                placeholder: L10n.categoryEmojiPickerSearchPlaceholder,
                onTextDidChanged: CommandOf { [weak handler] query in
                    await handler?.handleChangeSearchQuery(query)
                }
            ),
            state: rows.isEmpty
                ? .empty(
                    .init(
                        text: L10n.categoryEmojiPickerEmpty,
                        font: Typography.typographyMedium14,
                        textColor: Asset.Colors.textAndIconPlaceseholder.color,
                        alignment: .center,
                        numberOfLines: 0,
                        lineBreakMode: .byWordWrapping
                    )
                )
                : .loaded(rows: rows)
        )
    }
}
