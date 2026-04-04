import Foundation

protocol ExpenseAIEntryBusinessLogic: Sendable {
    func fetchData() async
}

protocol ExpenseAIEntryHandler: AnyObject, Sendable {
    func handleChangePrompt(_ text: String) async
    func handleTapProcess() async
    func handleTapClose() async
}

actor ExpenseAIEntryInteractor: ExpenseAIEntryBusinessLogic {
    private enum Constants {
        static let maximumCharacters = 280
    }

    private let presenter: ExpenseAIEntryPresentationLogic
    private let router: ExpenseAIEntryRoutingLogic

    private var promptText: String = ""

    init(
        presenter: ExpenseAIEntryPresentationLogic,
        router: ExpenseAIEntryRoutingLogic
    ) {
        self.presenter = presenter
        self.router = router
    }

    func fetchData() async {
        await presentFetchedData()
    }
}

private extension ExpenseAIEntryInteractor {
    func presentFetchedData() async {
        await presenter.presentFetchedData(
            ExpenseAIEntryFetchData(
                promptText: promptText,
                maximumCharacters: Constants.maximumCharacters
            )
        )
    }
}

extension ExpenseAIEntryInteractor: ExpenseAIEntryHandler {
    func handleChangePrompt(_ text: String) async {
        promptText = String(text.prefix(Constants.maximumCharacters))
        await presentFetchedData()
    }

    func handleTapProcess() async {
        await router.presentComingSoon()
    }

    func handleTapClose() async {
        await router.close()
    }
}
