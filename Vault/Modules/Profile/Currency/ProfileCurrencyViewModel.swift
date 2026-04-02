import Foundation

struct ProfileCurrencyViewModel: Equatable {
    let navigationTitle: Label.LabelViewModel
    let searchField: TextField.ViewModel
    let closeButton: CloseButtonViewModel
    let rows: [RowViewModel]

    init(
        navigationTitle: Label.LabelViewModel = .init(),
        searchField: TextField.ViewModel = .init(),
        closeButton: CloseButtonViewModel = .init(),
        rows: [RowViewModel] = []
    ) {
        self.navigationTitle = navigationTitle
        self.searchField = searchField
        self.closeButton = closeButton
        self.rows = rows
    }
}

extension ProfileCurrencyViewModel {
    struct RowViewModel: Equatable {
        let code: String
        let title: Label.LabelViewModel
        let subtitle: Label.LabelViewModel
        let isSelected: Bool
        let tapCommand: Command

        init(
            code: String = "",
            title: Label.LabelViewModel = .init(),
            subtitle: Label.LabelViewModel = .init(),
            isSelected: Bool = false,
            tapCommand: Command = .nope
        ) {
            self.code = code
            self.title = title
            self.subtitle = subtitle
            self.isSelected = isSelected
            self.tapCommand = tapCommand
        }
    }

    struct CloseButtonViewModel: Equatable {
        let tapCommand: Command

        init(tapCommand: Command = .nope) {
            self.tapCommand = tapCommand
        }
    }
}
