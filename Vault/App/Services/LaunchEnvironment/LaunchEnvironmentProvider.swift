// Created by Egor Shkarin on 28.10.2026

import Foundation

/// Reads QA overrides from the launch environment. Overrides are honored only in Debug builds.
final class LaunchEnvironmentProvider: LaunchEnvironmentProviding, Sendable {
    private enum Key {
        static let apiBaseURL = "VAULT_API_BASE_URL"
        static let qaMode = "VAULT_QA_MODE"
        static let qaSession = "VAULT_QA_SESSION"
    }

    static let shared = LaunchEnvironmentProvider()

    private let environment: [String: String]
    private let isOverrideAllowed: Bool

    init(
        environment: [String: String] = LaunchEnvironmentProvider.processValues,
        isOverrideAllowed: Bool = LaunchEnvironmentProvider.isDebugBuild
    ) {
        self.environment = environment
        self.isOverrideAllowed = isOverrideAllowed
    }

    var apiBaseURL: URL? {
        guard isOverrideAllowed,
              let value = environment[Key.apiBaseURL],
              let components = URLComponents(string: value),
              let scheme = components.scheme,
              ["http", "https"].contains(scheme),
              components.host?.isEmpty == false else {
            return nil
        }

        return components.url
    }

    var isQAMode: Bool {
        isOverrideAllowed && environment[Key.qaMode] == "1"
    }

    /// Raw `/auth/login` response used to start the app already signed in during QA runs.
    var qaSession: String? {
        guard isQAMode,
              let value = environment[Key.qaSession],
              !value.isEmpty else {
            return nil
        }

        return value
    }
}

extension LaunchEnvironmentProvider {
    static var isDebugBuild: Bool {
        #if DEBUG
        true
        #else
        false
        #endif
    }

    static var processValues: [String: String] {
        values(environment: ProcessInfo.processInfo.environment, arguments: ProcessInfo.processInfo.arguments)
    }

    /// Environment merged with `-KEY value` launch arguments, which is how Maestro passes values on iOS.
    static func values(environment: [String: String], arguments: [String]) -> [String: String] {
        var values = environment
        for (key, value) in zip(arguments, arguments.dropFirst()) where key.hasPrefix("-") && !value.hasPrefix("-") {
            values[String(key.dropFirst())] = value
        }
        return values
    }
}
