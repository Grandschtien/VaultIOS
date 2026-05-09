import Foundation

protocol AnalyticsServiceProtocol: Sendable {
    var provider: AnalyticsProvider { get }
    func send(event: AnalyticsEvent, payload: AnalyticsPayload) async
}

final class AnalyticsCoreManager: AnalyticsCoreManaging, @unchecked Sendable {
    private let dispatcher: Dispatcher
    private let userProfileStorageService: UserProfileStorageServiceProtocol

    init(
        services: [any AnalyticsServiceProtocol],
        userProfileStorageService: UserProfileStorageServiceProtocol
    ) {
        self.userProfileStorageService = userProfileStorageService
        dispatcher = Dispatcher(services: services)
    }

    func sendEvent(provider: AnalyticsProvider, event: AnalyticsEvent, payload: [String: Any]) {
        let normalizedPayload = AnalyticsPayload(
            rawPayload: mergedPayload(defaultPayload(), payload)
        )
        Task { await dispatcher.dispatch(provider: provider, event: event, payload: normalizedPayload) }
    }
}

private extension AnalyticsCoreManager {
    func defaultPayload() -> [String: Any] {
        [
            "date_utc": ISO8601DateFormatter().string(from: Date()),
            "user_id": userProfileStorageService.loadProfile()?.userId ?? ""
        ]
    }

    func mergedPayload(_ payloads: [String: Any]...) -> [String: Any] {
        payloads.reduce(into: [:]) { result, payload in
            result.merge(payload) { _, new in new }
        }
    }
}

private extension AnalyticsCoreManager {
    actor Dispatcher {
        private let services: [any AnalyticsServiceProtocol]

        init(services: [any AnalyticsServiceProtocol]) {
            self.services = services
        }

        func dispatch(provider: AnalyticsProvider, event: AnalyticsEvent, payload: AnalyticsPayload) async {
            let resolvedServices = resolvedServices(for: provider)
            guard !resolvedServices.isEmpty else { return }
            logDispatch(provider: provider, event: event, payload: payload)

            await withTaskGroup(of: Void.self) { group in
                for service in resolvedServices {
                    group.addTask { await service.send(event: event, payload: payload) }
                }
            }
        }

        func resolvedServices(for provider: AnalyticsProvider) -> [any AnalyticsServiceProtocol] {
            switch provider {
            case .all:
                services
            case .firebase:
                services.filter { $0.provider == .firebase }
            }
        }

        func logDispatch(provider: AnalyticsProvider, event: AnalyticsEvent, payload: AnalyticsPayload) {
            #if DEBUG
            print(
                "[Analytics] provider=\(provider.logName) event=\(event.name) payload=\(payload.logDescription)"
            )
            #endif
        }
    }
}

private extension AnalyticsProvider {
    var logName: String {
        switch self {
        case .all:
            "all"
        case .firebase:
            "firebase"
        }
    }
}
