import UIKit
internal import Combine

@MainActor
protocol CategoryEditorPresentationLogic: Sendable {
    func presentFetchedData(_ data: CategoryEditorFetchData)
}

final class CategoryEditorPresenter: CategoryEditorPresentationLogic {
    @Published
    private(set) var viewModel: CategoryEditorViewModel

    weak var handler: CategoryEditorHandler?

    private let presetProvider: CategoryEditorPresetProviding
    private let colorProvider: CategoryColorProviding

    init(
        viewModel: CategoryEditorViewModel,
        presetProvider: CategoryEditorPresetProviding,
        colorProvider: CategoryColorProviding
    ) {
        self.viewModel = viewModel
        self.presetProvider = presetProvider
        self.colorProvider = colorProvider
    }

    func presentFetchedData(_ data: CategoryEditorFetchData) {
        viewModel = CategoryEditorViewModel(
            header: .init(
                title: .init(
                    text: title(for: data.mode),
                    font: Typography.typographyBold20,
                    textColor: Asset.Colors.textAndIconPrimary.color,
                    alignment: .center
                ),
                backCommand: Command { [weak handler] in
                    await handler?.handleTapBackButton()
                }
            ),
            state: makeState(from: data),
            primaryButton: .init(
                title: primaryButtonTitle(for: data.mode),
                titleColor: Asset.Colors.textAndIconPrimaryInverted.color,
                backgroundColor: Asset.Colors.interactiveElemetsPrimary.color,
                font: Typography.typographySemibold16,
                isEnabled: data.isPrimaryEnabled,
                isLoading: data.isPrimaryLoading,
                tapCommand: Command { [weak handler] in
                    await handler?.handleTapPrimaryButton()
                }
            ),
            deleteButton: makeDeleteButton(from: data)
        )
    }
}

private extension CategoryEditorPresenter {
    func makeState(from data: CategoryEditorFetchData) -> CategoryEditorViewModel.State {
        switch data.loadingState {
        case .idle, .loading:
            return .loading
        case .failed:
            return .error(
                .init(
                    title: .init(
                        text: L10n.mainOverviewError,
                        font: Typography.typographyBold14,
                        textColor: Asset.Colors.textAndIconSecondary.color,
                        alignment: .center
                    ),
                    tapCommand: Command { [weak handler] in
                        await handler?.handleTapRetryButton()
                    }
                )
            )
        case .loaded:
            return .loaded(
                .init(
                    preview: .init(
                        emojiText: data.draft.emoji,
                        backgroundColor: colorProvider.color(for: data.draft.colorHex)
                    ),
                    nameField: .init(
                        text: data.draft.name,
                        placeholder: L10n.categoryEditorNamePlaceholder,
                        titleText: L10n.categoryEditorNameTitle,
                        helpText: data.shouldShowNameError ? L10n.commonFillField : nil,
                        helpTextColor: Asset.Colors.errorColor.color,
                        onTextDidChanged: CommandOf { [weak handler] text in
                            await handler?.handleChangeCategoryName(text)
                        }
                    ),
                    emojiTitle: .init(
                        text: L10n.categoryEditorEmojiTitle,
                        font: Typography.typographySemibold14,
                        textColor: Asset.Colors.textAndIconSecondary.color,
                        alignment: .left
                    ),
                    emojiItems: makeEmojiItems(from: data),
                    colorTitle: .init(
                        text: L10n.categoryEditorColorTitle,
                        font: Typography.typographySemibold14,
                        textColor: Asset.Colors.textAndIconSecondary.color,
                        alignment: .left
                    ),
                    colorItems: makeColorItems(from: data)
                )
            )
        }
    }

    func makeDeleteButton(from data: CategoryEditorFetchData) -> Button.ButtonViewModel? {
        guard data.isDeleteVisible else {
            return nil
        }

        return .init(
            title: L10n.categoryEditorDeleteButton,
            titleColor: Asset.Colors.errorColor.color,
            backgroundColor: .clear,
            font: Typography.typographySemibold16,
            isEnabled: !data.isPrimaryLoading,
            isLoading: data.isDeleteLoading,
            tapCommand: Command { [weak handler] in
                await handler?.handleTapDeleteButton()
            }
        )
    }

    func makeEmojiItems(
        from data: CategoryEditorFetchData
    ) -> [CategoryEditorOptionView.ViewModel] {
        let presetEmojis = presetProvider.emojiPresets()
        let shouldPinPrefilledEmoji = data.prefilledCustomEmoji == data.draft.emoji
        let presets = shouldPinPrefilledEmoji
            ? pinnedEmojis(prefilledEmoji: data.draft.emoji, presets: presetEmojis)
            : presetEmojis
        let selectedBorderColor = Asset.Colors.interactiveElemetsPrimary.color
        let backgroundColor = Asset.Colors.interactiveInputBackground.color

        let presetItems = presets.map { emoji in
            CategoryEditorOptionView.ViewModel(
                content: .emoji(emoji),
                backgroundColor: backgroundColor,
                foregroundColor: Asset.Colors.textAndIconPrimary.color,
                borderColor: data.draft.emoji == emoji ? selectedBorderColor : .clear,
                borderWidth: data.draft.emoji == emoji ? 2 : .zero,
                tapCommand: Command { [weak handler] in
                    await handler?.handleTapEmojiPreset(emoji)
                }
            )
        }

        let isCustomSelected = !presets.contains(data.draft.emoji)
        let customItem = CategoryEditorOptionView.ViewModel(
            content: isCustomSelected ? .emoji(data.draft.emoji) : .symbol("plus"),
            backgroundColor: backgroundColor,
            foregroundColor: Asset.Colors.textAndIconSecondary.color,
            borderColor: isCustomSelected ? selectedBorderColor : .clear,
            borderWidth: isCustomSelected ? 2 : .zero,
            tapCommand: Command { [weak handler] in
                await handler?.handleTapCustomEmojiButton()
            }
        )

        return presetItems + [customItem]
    }

    func makeColorItems(
        from data: CategoryEditorFetchData
    ) -> [CategoryEditorOptionView.ViewModel] {
        let presetColors = presetProvider.colorPresets()
        let shouldPinPrefilledColor = data.prefilledCustomColorHex == data.draft.colorHex
        let presets = shouldPinPrefilledColor
            ? pinnedColors(prefilledHex: data.draft.colorHex, presets: presetColors)
            : presetColors
        let selectedBorderColor = Asset.Colors.interactiveElemetsPrimary.color

        let presetItems = presets.map { hex in
            CategoryEditorOptionView.ViewModel(
                content: .none,
                backgroundColor: colorProvider.color(for: hex),
                foregroundColor: colorProvider.color(for: hex),
                borderColor: data.draft.colorHex == hex ? selectedBorderColor : .clear,
                borderWidth: data.draft.colorHex == hex ? 2 : .zero,
                tapCommand: Command { [weak handler] in
                    await handler?.handleTapColorPreset(hex)
                }
            )
        }

        let isCustomSelected = !presets.contains(data.draft.colorHex)
        let customItem = CategoryEditorOptionView.ViewModel(
            content: .symbol("plus"),
            backgroundColor: isCustomSelected
                ? colorProvider.color(for: data.draft.colorHex)
                : .white,
            foregroundColor: isCustomSelected
                ? Asset.Colors.textAndIconPrimary.color
                : Asset.Colors.textAndIconSecondary.color,
            borderColor: isCustomSelected ? selectedBorderColor : .clear,
            borderWidth: isCustomSelected ? 2 : .zero,
            tapCommand: Command { [weak handler] in
                await handler?.handleTapCustomColorButton()
            }
        )

        return presetItems + [customItem]
    }

    func title(for mode: CategoryEditorMode) -> String {
        switch mode {
        case .create:
            L10n.categoryEditorAddTitle
        case .edit:
            L10n.categoryEditorEditTitle
        }
    }

    func primaryButtonTitle(for mode: CategoryEditorMode) -> String {
        switch mode {
        case .create:
            L10n.categoryEditorAddButton
        case .edit:
            L10n.categoryEditorSaveButton
        }
    }

    func pinnedEmojis(prefilledEmoji: String, presets: [String]) -> [String] {
        Array(([prefilledEmoji] + presets).prefix(7))
    }

    func pinnedColors(prefilledHex: String, presets: [String]) -> [String] {
        Array(([prefilledHex] + presets).prefix(7))
    }
}
