import Foundation

enum CategoryEditorMode: Equatable, Sendable {
    case create
    case edit(id: String)

    var categoryID: String? {
        switch self {
        case .create:
            nil
        case let .edit(id):
            id
        }
    }
}
