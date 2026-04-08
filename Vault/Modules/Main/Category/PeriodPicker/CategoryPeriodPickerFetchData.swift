import Foundation

struct CategoryPeriodPickerFetchData: Sendable {
    let fromDate: Date
    let toDate: Date
    let activeField: MainPeriodPickerActiveField
    let selectedCalendarDate: Date
    let visibleMonthDate: Date
    let minimumDate: Date
    let maximumDate: Date
    let isApplyEnabled: Bool

    init(
        fromDate: Date,
        toDate: Date,
        activeField: MainPeriodPickerActiveField,
        selectedCalendarDate: Date,
        visibleMonthDate: Date,
        minimumDate: Date,
        maximumDate: Date,
        isApplyEnabled: Bool
    ) {
        self.fromDate = fromDate
        self.toDate = toDate
        self.activeField = activeField
        self.selectedCalendarDate = selectedCalendarDate
        self.visibleMonthDate = visibleMonthDate
        self.minimumDate = minimumDate
        self.maximumDate = maximumDate
        self.isApplyEnabled = isApplyEnabled
    }
}
