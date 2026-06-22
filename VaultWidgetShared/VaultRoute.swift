import Foundation

enum VaultRoute: Equatable, Sendable {
    case home
    case aiEntry

    var url: URL {
        switch self {
        case .home:
            URL(string: "vault://home")!
        case .aiEntry:
            URL(string: "vault://add-expense/ai-entry")!
        }
    }
}
