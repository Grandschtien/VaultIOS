import Foundation

struct AIParseRequestDTO: Codable, Equatable, Sendable {
    let text: String
    let currencyHint: String
}
