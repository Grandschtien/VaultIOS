import Foundation

struct CategoryPeriodPickerFetchData: Sendable {
    let selectedDate: Date
    let minimumDate: Date
    let maximumDate: Date

    init(
        selectedDate: Date,
        minimumDate: Date,
        maximumDate: Date
    ) {
        self.selectedDate = selectedDate
        self.minimumDate = minimumDate
        self.maximumDate = maximumDate
    }
}
