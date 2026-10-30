// Created by Egor Shkarin 29.10.2026

import Foundation

// Not AutoMockable: tests use the shared VaultTests/Support/Mocks/NotificationCenterMock.swift
protocol NotificationCenterServicing: Sendable {
    func addObserver(
        forName name: Notification.Name,
        handler: @escaping @Sendable () async -> Void
    ) -> NSObjectProtocol
    func removeObserver(_ observer: NSObjectProtocol)
}

final class NotificationCenterService: NotificationCenterServicing, @unchecked Sendable {
    private let notificationCenter: NotificationCenter

    init(notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter
    }

    func addObserver(
        forName name: Notification.Name,
        handler: @escaping @Sendable () async -> Void
    ) -> NSObjectProtocol {
        notificationCenter.addObserver(
            forName: name,
            object: nil,
            queue: nil
        ) { _ in
            Task {
                await handler()
            }
        }
    }

    func removeObserver(_ observer: NSObjectProtocol) {
        notificationCenter.removeObserver(observer)
    }
}
