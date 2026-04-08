import Foundation

protocol CategoryPeriodPickerBusinessLogic: Sendable {
    func fetchData() async
}

protocol CategoryPeriodPickerOutput: AnyObject, Sendable {
    func handleDidConfirmCategoryPeriod(
        fromDate: Date,
        to date: Date
    ) async
}

protocol CategoryPeriodPickerHandler: AnyObject, Sendable {
    func handleTapFromField() async
    func handleTapToField() async
    func handleSelectDate(_ date: Date) async
    func handleTapConfirm() async
    func handleTapClose() async
}

actor CategoryPeriodPickerInteractor: CategoryPeriodPickerBusinessLogic {
    private let presenter: CategoryPeriodPickerPresentationLogic
    private let router: CategoryPeriodPickerRoutingLogic
    private let output: CategoryPeriodPickerOutput
    private let now: @Sendable () -> Date
    private let resolver: MainPeriodRangeResolver

    private var fromDate: Date
    private var toDate: Date
    private var activeField: MainPeriodPickerActiveField
    private var visibleMonthDate: Date

    init(
        presenter: CategoryPeriodPickerPresentationLogic,
        router: CategoryPeriodPickerRoutingLogic,
        output: CategoryPeriodPickerOutput,
        fromDate: Date,
        toDate: Date,
        calendar: Calendar = .current,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        let resolver = MainPeriodRangeResolver(calendar: calendar)
        let initialPickerState = resolver.pickerState(
            for: .init(from: fromDate, to: toDate),
            activeField: .to,
            now: now()
        )

        self.presenter = presenter
        self.router = router
        self.output = output
        self.now = now
        self.resolver = resolver
        self.fromDate = initialPickerState.fromDate
        self.toDate = initialPickerState.toDate
        activeField = initialPickerState.activeField
        visibleMonthDate = initialPickerState.visibleMonthDate
    }

    func fetchData() async {
        await presentFetchedData()
    }
}

private extension CategoryPeriodPickerInteractor {
    func presentFetchedData() async {
        let state = pickerState(now: now())
        await presenter.presentFetchedData(
            .init(
                fromDate: state.fromDate,
                toDate: state.toDate,
                activeField: state.activeField,
                selectedCalendarDate: state.selectedCalendarDate,
                visibleMonthDate: state.visibleMonthDate,
                minimumDate: state.minimumDate,
                maximumDate: state.maximumDate,
                isApplyEnabled: state.isApplyEnabled
            )
        )
    }

    func pickerState(now currentDate: Date) -> MainPeriodPickerState {
        resolver.pickerState(
            from: fromDate,
            to: toDate,
            activeField: activeField,
            visibleMonthDate: visibleMonthDate,
            now: currentDate
        )
    }
}

extension CategoryPeriodPickerInteractor: CategoryPeriodPickerHandler {
    func handleTapFromField() async {
        activeField = .from
        visibleMonthDate = resolver.startOfMonth(for: fromDate)
        await presentFetchedData()
    }

    func handleTapToField() async {
        activeField = .to
        visibleMonthDate = resolver.startOfMonth(for: toDate)
        await presentFetchedData()
    }

    func handleSelectDate(_ date: Date) async {
        switch activeField {
        case .from:
            fromDate = resolver.startOfDay(for: date)
        case .to:
            toDate = resolver.normalizedToDate(for: date, now: now())
        }

        visibleMonthDate = resolver.startOfMonth(for: date)
        await presentFetchedData()
    }
    func handleTapConfirm() async {
        let currentDate = now()
        let state = pickerState(now: currentDate)
        guard state.isApplyEnabled else {
            return
        }

        let period = resolver.explicitPeriod(
            from: fromDate,
            to: toDate,
            now: currentDate
        )
        await output.handleDidConfirmCategoryPeriod(
            fromDate: period.from,
            to: period.to
        )
        await router.close()
    }

    func handleTapClose() async {
        await router.close()
    }
}
