import Foundation

struct AppLogEntry: Equatable, Sendable, Encodable {
    let timestamp_utc: String
    let session_id: String
    let category: AppLogCategory
    let name: String
    let source: String
    let payload: [String: AppLogValue]
    let request_id: String?
    let subscription_attempt_id: String?

    func encodedLine() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]

        guard let data = try? encoder.encode(self) else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }
}

enum AppLogValue: Equatable, Sendable, Encodable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([AppLogValue])

    init(rawValue: Any) {
        switch rawValue {
        case let value as String:
            self = .string(value)
        case let value as NSString:
            self = .string(value as String)
        case let value as Bool:
            self = .bool(value)
        case let value as Int:
            self = .int(value)
        case let value as Double:
            self = .double(value)
        case let value as NSNumber:
            self = Self.normalizedValue(from: value)
        case let value as [Any]:
            self = .array(value.map(Self.init(rawValue:)))
        case let value as NSArray:
            self = .array(value.compactMap { $0 }.map(Self.init(rawValue:)))
        default:
            self = .string(String(describing: rawValue))
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        }
    }
}

private extension AppLogValue {
    static func normalizedValue(from number: NSNumber) -> AppLogValue {
        let type = String(cString: number.objCType)

        switch type {
        case "B":
            return .bool(number.boolValue)
        case "c" where CFGetTypeID(number) == CFBooleanGetTypeID():
            return .bool(number.boolValue)
        case "s", "i", "l", "q", "S", "I", "L", "Q", "c":
            return .int(number.intValue)
        default:
            return .double(number.doubleValue)
        }
    }
}
