import Foundation

struct ProfileCurrencyFetchData: Sendable {
    let navigationTitle: String
    let searchQuery: String
    let currencies: [RegistrationCurrency]
    let selectedCurrencyCode: String

    init(
        navigationTitle: String = L10n.profileSelectCurrencyTitle,
        searchQuery: String = "",
        currencies: [RegistrationCurrency] = [],
        selectedCurrencyCode: String = ""
    ) {
        self.navigationTitle = navigationTitle
        self.searchQuery = searchQuery
        self.currencies = currencies
        self.selectedCurrencyCode = selectedCurrencyCode
    }
}
