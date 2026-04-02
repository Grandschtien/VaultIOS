import Foundation

protocol ProfileCurrencyBusinessLogic: Sendable {
    func fetchData() async
}

protocol ProfileCurrencySelectionOutput: AnyObject, Sendable {
    func handleDidSelectCurrency(_ currencyCode: String) async
}

protocol ProfileCurrencyHandler: AnyObject, Sendable {
    func handleSelectCurrency(_ currencyCode: String) async
    func handleSearchQueryDidChange(_ query: String) async
    func handleTapClose() async
}

actor ProfileCurrencyInteractor: ProfileCurrencyBusinessLogic {
    private let presenter: ProfileCurrencyPresentationLogic
    private let router: ProfileCurrencyRoutingLogic
    private let currencyProvider: RegistrationCurrencyProviding
    private let output: ProfileCurrencySelectionOutput

    private var allCurrencies: [RegistrationCurrency] = []
    private var searchQuery: String = ""
    private var selectedCurrencyCode: String

    init(
        presenter: ProfileCurrencyPresentationLogic,
        router: ProfileCurrencyRoutingLogic,
        currencyProvider: RegistrationCurrencyProviding,
        output: ProfileCurrencySelectionOutput,
        currentCurrencyCode: String
    ) {
        self.presenter = presenter
        self.router = router
        self.currencyProvider = currencyProvider
        self.output = output
        self.selectedCurrencyCode = currentCurrencyCode
    }

    func fetchData() async {
        allCurrencies = currencyProvider.fiatCurrencies()
        await presentFetchedData()
    }
}

private extension ProfileCurrencyInteractor {
    func presentFetchedData() async {
        await presenter.presentFetchedData(
            ProfileCurrencyFetchData(
                searchQuery: searchQuery,
                currencies: filteredCurrencies(),
                selectedCurrencyCode: selectedCurrencyCode
            )
        )
    }

    func normalizeCurrencyCode(_ code: String) -> String {
        code
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
    }

    func filteredCurrencies() -> [RegistrationCurrency] {
        let normalizedQuery = searchQuery
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard !normalizedQuery.isEmpty else {
            return allCurrencies
        }

        return allCurrencies.filter {
            $0.code.lowercased().contains(normalizedQuery)
                || $0.title.lowercased().contains(normalizedQuery)
        }
    }
}

extension ProfileCurrencyInteractor: ProfileCurrencyHandler {
    func handleSelectCurrency(_ currencyCode: String) async {
        let normalizedCode = normalizeCurrencyCode(currencyCode)
        guard allCurrencies.contains(where: { $0.code == normalizedCode }) else {
            return
        }

        selectedCurrencyCode = normalizedCode
        await output.handleDidSelectCurrency(normalizedCode)
        await router.close()
    }

    func handleSearchQueryDidChange(_ query: String) async {
        searchQuery = query
        await presentFetchedData()
    }

    func handleTapClose() async {
        await router.close()
    }
}
