import Foundation

protocol CategoryPeriodPickerBusinessLogic: Sendable {
    func fetchData() async
}

protocol CategoryPeriodPickerOutput: AnyObject, Sendable {
    func handleDidConfirmCategoryPeriod(fromDate: Date) async
}

protocol CategoryPeriodPickerHandler: AnyObject, Sendable {
    func handleSelectDate(_ date: Date) async
    func handleTapConfirm() async
    func handleTapClose() async
}

actor CategoryPeriodPickerInteractor: CategoryPeriodPickerBusinessLogic {
    private let presenter: CategoryPeriodPickerPresentationLogic
    private let router: CategoryPeriodPickerRoutingLogic
    private let output: CategoryPeriodPickerOutput
    private let calendar: Calendar

    private var selectedDate: Date

    init(
        presenter: CategoryPeriodPickerPresentationLogic,
        router: CategoryPeriodPickerRoutingLogic,
        output: CategoryPeriodPickerOutput,
        selectedDate: Date,
        calendar: Calendar = .current
    ) {
        self.presenter = presenter
        self.router = router
        self.output = output
        self.calendar = calendar
        self.selectedDate = calendar.startOfDay(for: selectedDate)
    }

    func fetchData() async {
        await presentFetchedData()
    }
}

private extension CategoryPeriodPickerInteractor {
    func presentFetchedData() async {
        await presenter.presentFetchedData(
            .init(
                selectedDate: selectedDate,
                minimumDate: minimumDate(),
                maximumDate: calendar.startOfDay(for: Date())
            )
        )
    }

    func minimumDate() -> Date {
        calendar.date(
            from: DateComponents(
                calendar: calendar,
                year: 1,
                month: 1,
                day: 1
            )
        ) ?? calendar.startOfDay(for: Date.distantPast)
    }
}

extension CategoryPeriodPickerInteractor: CategoryPeriodPickerHandler {
    func handleSelectDate(_ date: Date) async {
        selectedDate = calendar.startOfDay(for: date)
        await presentFetchedData()
    }

    func handleTapConfirm() async {
        await output.handleDidConfirmCategoryPeriod(fromDate: selectedDate)
        await router.close()
    }

    func handleTapClose() async {
        await router.close()
    }
}
