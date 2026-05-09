import Foundation

struct AnalyticsPayload: Equatable, Sendable {
    enum Value: Equatable, Sendable {
        case string(String)
        case int(Int)
        case double(Double)
        case bool(Bool)
        case array([Value])
    }

    let values: [String: Value]

    init(rawPayload: [String: Any]) {
        values = rawPayload.reduce(into: [:]) { partialResult, element in
            guard let value = Self.makeValue(from: element.value, keyPath: element.key) else {
                Self.reportUnsupportedValue(forKey: element.key, value: element.value)
                return
            }
            partialResult[element.key] = value
        }
    }

    var foundationValues: [String: Any]? {
        guard !values.isEmpty else { return nil }
        return values.reduce(into: [String: Any]()) { partialResult, element in
            partialResult[element.key] = element.value.foundationValue
        }
    }

    var logDescription: String {
        guard let foundationValues else { return "{}" }
        return foundationValues.description
    }
}

private extension AnalyticsPayload {
    static func makeValue(from rawValue: Any, keyPath: String) -> Value? {
        switch rawValue {
        case let value as String:
            return .string(value)
        case let value as NSString:
            return .string(value as String)
        case let value as Bool:
            return .bool(value)
        case let value as Int:
            return .int(value)
        case let value as Double:
            return .double(value)
        case let value as NSNumber:
            return normalizedValue(from: value)
        case let value as [Any]:
            return normalizedArray(from: value, keyPath: keyPath)
        case let value as NSArray:
            return normalizedArray(from: value.compactMap { $0 }, keyPath: keyPath)
        default:
            return nil
        }
    }

    static func normalizedArray(from rawValues: [Any], keyPath: String) -> Value? {
        let normalizedValues = rawValues.enumerated().compactMap { index, rawValue -> Value? in
            let itemKeyPath = "\(keyPath)[\(index)]"

            guard let value = makeValue(from: rawValue, keyPath: itemKeyPath) else {
                reportUnsupportedValue(forKey: itemKeyPath, value: rawValue)
                return nil
            }

            return value
        }

        if normalizedValues.isEmpty && !rawValues.isEmpty {
            return nil
        }

        return .array(normalizedValues)
    }

    static func normalizedValue(from number: NSNumber) -> Value {
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

    static func reportUnsupportedValue(forKey key: String, value: Any) {
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil {
            assertionFailure("Unsupported analytics payload value for key \(key): \(value)")
        }
        #endif
    }
}

private extension AnalyticsPayload.Value {
    var foundationValue: Any {
        switch self {
        case .string(let value): value
        case .int(let value): value
        case .double(let value): value
        case .bool(let value): value
        case .array(let values): values.map(\.foundationValue)
        }
    }
}
