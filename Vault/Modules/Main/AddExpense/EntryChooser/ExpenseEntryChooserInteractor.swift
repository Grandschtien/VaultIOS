import Foundation

protocol ExpenseEntryChooserBusinessLogic: Sendable {
    func fetchData() async
}

protocol ExpenseEntryChooserHandler: AnyObject, Sendable {
    func handleTapClose() async
    func handleTapAiEntry() async
    func handleTapManualEntry() async
}

actor ExpenseEntryChooserInteractor: ExpenseEntryChooserBusinessLogic {
    private let presenter: ExpenseEntryChooserPresentationLogic
    private let router: ExpenseEntryChooserRoutingLogic

    init(
        presenter: ExpenseEntryChooserPresentationLogic,
        router: ExpenseEntryChooserRoutingLogic
    ) {
        self.presenter = presenter
        self.router = router
    }

    func fetchData() async {
        await presenter.presentFetchedData(.init())
    }
}

extension ExpenseEntryChooserInteractor: ExpenseEntryChooserHandler {
    func handleTapClose() async {
        await router.close()
    }

    func handleTapAiEntry() async {
        await router.openAiEntry()
    }

    func handleTapManualEntry() async {
        await router.openManualEntry()
    }
}
