import Foundation

protocol VaultRouteParsing: Sendable {
    func parse(url: URL) -> VaultRoute?
}

struct VaultRouteParser: VaultRouteParsing {
    func parse(url: URL) -> VaultRoute? {
        guard let components = URLComponents(
            url: url,
            resolvingAgainstBaseURL: false
        ),
        components.scheme?.lowercased() == "vault" else {
            return nil
        }

        let host = components.host?.lowercased()
        let path = components.path.lowercased()

        switch (host, path) {
        case ("home", ""):
            return .home
        case ("add-expense", "/ai-entry"):
            return .aiEntry
        case ("subscription", ""):
            return .subscription
        default:
            return nil
        }
    }
}
