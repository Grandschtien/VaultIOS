import UIKit

struct ExpenseCategoryPickerViewModel: Equatable {
    let header: AddExpenseSheetHeaderView.ViewModel
    let state: State
    let createButton: Button.ButtonViewModel
    let addButton: Button.ButtonViewModel

    init(
        header: AddExpenseSheetHeaderView.ViewModel = .init(),
        state: State = .loading(rows: []),
        createButton: Button.ButtonViewModel = .init(),
        addButton: Button.ButtonViewModel = .init()
    ) {
        self.header = header
        self.state = state
        self.createButton = createButton
        self.addButton = addButton
    }
}

extension ExpenseCategoryPickerViewModel {
    enum State: Equatable {
        case error(FullScreenCommonErrorView.ViewModel)
        case empty(Label.LabelViewModel)
        case loading(rows: [RowViewModel])
        case loaded(rows: [RowViewModel])
    }

    struct RowViewModel: Equatable {
        let id: String
        let iconText: String
        let title: Label.LabelViewModel
        let iconBackgroundColor: UIColor
        let isSelected: Bool
        let tapCommand: Command
        let isLoading: Bool

        init(
            id: String = "",
            iconText: String = "",
            title: Label.LabelViewModel = .init(),
            iconBackgroundColor: UIColor = Asset.Colors.interactiveInputBackground.color,
            isSelected: Bool = false,
            tapCommand: Command = .nope,
            isLoading: Bool = false
        ) {
            self.id = id
            self.iconText = iconText
            self.title = title
            self.iconBackgroundColor = iconBackgroundColor
            self.isSelected = isSelected
            self.tapCommand = tapCommand
            self.isLoading = isLoading
        }
    }
}
