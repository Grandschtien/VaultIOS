import Foundation

struct CategoryPeriodPickerViewModel: Equatable {
    let navigationTitle: Label.LabelViewModel
    let calendar: CalendarViewModel
    let closeButton: CloseButtonViewModel
    let confirmButton: ConfirmButtonViewModel

    init(
        navigationTitle: Label.LabelViewModel = .init(),
        calendar: CalendarViewModel = .init(),
        closeButton: CloseButtonViewModel = .init(),
        confirmButton: ConfirmButtonViewModel = .init()
    ) {
        self.navigationTitle = navigationTitle
        self.calendar = calendar
        self.closeButton = closeButton
        self.confirmButton = confirmButton
    }
}

extension CategoryPeriodPickerViewModel {
    struct CalendarViewModel: Equatable {
        let selectedDate: Date
        let minimumDate: Date
        let maximumDate: Date
        let selectionCommand: CommandOf<Date>

        init(
            selectedDate: Date = Date(),
            minimumDate: Date = Date(),
            maximumDate: Date = Date(),
            selectionCommand: CommandOf<Date> = .init(action: nil)
        ) {
            self.selectedDate = selectedDate
            self.minimumDate = minimumDate
            self.maximumDate = maximumDate
            self.selectionCommand = selectionCommand
        }
    }

    struct CloseButtonViewModel: Equatable {
        let tapCommand: Command

        init(tapCommand: Command = .nope) {
            self.tapCommand = tapCommand
        }
    }

    struct ConfirmButtonViewModel: Equatable {
        let title: String
        let tapCommand: Command

        init(
            title: String = "",
            tapCommand: Command = .nope
        ) {
            self.title = title
            self.tapCommand = tapCommand
        }
    }
}
