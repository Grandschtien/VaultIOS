import UIKit

struct CategoryEditorViewModel: Equatable {
    let header: CategoryEditorHeaderView.ViewModel
    let state: State
    let primaryButton: Button.ButtonViewModel
    let deleteButton: Button.ButtonViewModel?

    init(
        header: CategoryEditorHeaderView.ViewModel = .init(),
        state: State = .loading,
        primaryButton: Button.ButtonViewModel = .init(),
        deleteButton: Button.ButtonViewModel? = nil
    ) {
        self.header = header
        self.state = state
        self.primaryButton = primaryButton
        self.deleteButton = deleteButton
    }
}

extension CategoryEditorViewModel {
    enum State: Equatable {
        case loading
        case error(FullScreenCommonErrorView.ViewModel)
        case loaded(ContentViewModel)
    }

    struct ContentViewModel: Equatable {
        let preview: PreviewViewModel
        let nameField: TextField.ViewModel
        let emojiTitle: Label.LabelViewModel
        let emojiItems: [CategoryEditorOptionView.ViewModel]
        let customEmojiFocusID: UUID?
        let onCustomEmojiSelected: CommandOf<String>
        let colorTitle: Label.LabelViewModel
        let colorItems: [CategoryEditorOptionView.ViewModel]

        init(
            preview: PreviewViewModel = .init(),
            nameField: TextField.ViewModel = .init(),
            emojiTitle: Label.LabelViewModel = .init(),
            emojiItems: [CategoryEditorOptionView.ViewModel] = [],
            customEmojiFocusID: UUID? = nil,
            onCustomEmojiSelected: CommandOf<String> = .init(action: nil),
            colorTitle: Label.LabelViewModel = .init(),
            colorItems: [CategoryEditorOptionView.ViewModel] = []
        ) {
            self.preview = preview
            self.nameField = nameField
            self.emojiTitle = emojiTitle
            self.emojiItems = emojiItems
            self.customEmojiFocusID = customEmojiFocusID
            self.onCustomEmojiSelected = onCustomEmojiSelected
            self.colorTitle = colorTitle
            self.colorItems = colorItems
        }
    }

    struct PreviewViewModel: Equatable {
        let emojiText: String
        let backgroundColor: UIColor

        init(
            emojiText: String = "",
            backgroundColor: UIColor = Asset.Colors.interactiveInputBackground.color
        ) {
            self.emojiText = emojiText
            self.backgroundColor = backgroundColor
        }
    }
}
