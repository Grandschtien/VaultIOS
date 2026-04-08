import Foundation

struct CategoryPeriodPickerViewModel: Equatable {
    let navigationTitle: Label.LabelViewModel
    let fromField: PeriodFieldViewModel
    let toField: PeriodFieldViewModel
    let calendar: CalendarViewModel
    let closeButton: CloseButtonViewModel
    let confirmButton: ConfirmButtonViewModel

    init(
        navigationTitle: Label.LabelViewModel = .init(),
        fromField: PeriodFieldViewModel = .init(),
        toField: PeriodFieldViewModel = .init(),
        calendar: CalendarViewModel = .init(),
        closeButton: CloseButtonViewModel = .init(),
        confirmButton: ConfirmButtonViewModel = .init()
    ) {
        self.navigationTitle = navigationTitle
        self.fromField = fromField
        self.toField = toField
        self.calendar = calendar
        self.closeButton = closeButton
        self.confirmButton = confirmButton
    }
}

extension CategoryPeriodPickerViewModel {
    struct PeriodFieldViewModel: Equatable {
        let title: Label.LabelViewModel
        let value: Label.LabelViewModel
        let isActive: Bool
        let tapCommand: Command

        init(
            title: Label.LabelViewModel = .init(),
            value: Label.LabelViewModel = .init(),
            isActive: Bool = false,
            tapCommand: Command = .nope
        ) {
            self.title = title
            self.value = value
            self.isActive = isActive
            self.tapCommand = tapCommand
        }
    }

    struct CalendarViewModel: Equatable {
        let selectedDate: Date
        let visibleMonthDate: Date
        let minimumDate: Date
        let maximumDate: Date
        let selectionCommand: CommandOf<Date>

        init(
            selectedDate: Date = Date(),
            visibleMonthDate: Date = Date(),
            minimumDate: Date = Date(),
            maximumDate: Date = Date(),
            selectionCommand: CommandOf<Date> = .init(action: nil)
        ) {
            self.selectedDate = selectedDate
            self.visibleMonthDate = visibleMonthDate
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
        let isEnabled: Bool
        let tapCommand: Command

        init(
            title: String = "",
            isEnabled: Bool = true,
            tapCommand: Command = .nope
        ) {
            self.title = title
            self.isEnabled = isEnabled
            self.tapCommand = tapCommand
        }
    }
}
