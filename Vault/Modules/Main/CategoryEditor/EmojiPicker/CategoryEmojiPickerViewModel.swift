import Foundation

struct CategoryEmojiPickerViewModel: Equatable {
    let header: AddExpenseSheetHeaderView.ViewModel
    let searchField: TextField.ViewModel
    let state: State

    init(
        header: AddExpenseSheetHeaderView.ViewModel = .init(),
        searchField: TextField.ViewModel = .init(),
        state: State = .loaded(rows: [])
    ) {
        self.header = header
        self.searchField = searchField
        self.state = state
    }
}

extension CategoryEmojiPickerViewModel {
    enum State: Equatable {
        case empty(Label.LabelViewModel)
        case loaded(rows: [RowViewModel])
    }

    struct RowViewModel: Equatable {
        let emoji: String
        let isSelected: Bool
        let tapCommand: Command

        init(
            emoji: String = "",
            isSelected: Bool = false,
            tapCommand: Command = .nope
        ) {
            self.emoji = emoji
            self.isSelected = isSelected
            self.tapCommand = tapCommand
        }
    }
}
