// Created by Egor Shkarin 11.04.2026

import Foundation
import UIKit

enum SubscriptionTierState: Equatable, Sendable {
    case resolved(SubscriptionTier)
    case unavailable

    var tier: SubscriptionTier {
        switch self {
        case .resolved(let tier):
            tier
        case .unavailable:
            .regular
        }
    }
}

enum SubscriptionTierRefreshState: Equatable, Sendable {
    case network(SubscriptionTier)
    case cache(SubscriptionTier)
    case unavailable

    var tierState: SubscriptionTierState {
        switch self {
        case .network(let tier), .cache(let tier):
            .resolved(tier)
        case .unavailable:
            .unavailable
        }
    }
}

enum SubscriptionAccessRefreshState: Equatable, Sendable {
    case network(SubscriptionAccessSnapshot)
    case cache(SubscriptionAccessSnapshot)
    case unavailable

    var snapshot: SubscriptionAccessSnapshot? {
        switch self {
        case .network(let snapshot), .cache(let snapshot):
            snapshot
        case .unavailable:
            nil
        }
    }

    var tierRefreshState: SubscriptionTierRefreshState {
        switch self {
        case .network(let snapshot):
            .network(snapshot.tier)
        case .cache(let snapshot):
            .cache(snapshot.tier)
        case .unavailable:
            .unavailable
        }
    }
}

protocol SubscriptionAccessServicing: Sendable {
    func currentTierState() async -> SubscriptionTierState
    func refreshCurrentTierState() async -> SubscriptionTierState
    func refreshCurrentTierSourceState() async -> SubscriptionTierRefreshState
    func currentSubscriptionSnapshot() async -> SubscriptionAccessSnapshot?
    func refreshCurrentSubscriptionSnapshot() async -> SubscriptionAccessSnapshot?
    func startMonitoring()
}

extension SubscriptionAccessServicing {
    func currentTier() async -> SubscriptionTier {
        await currentTierState().tier
    }

    func refreshCurrentTier() async -> SubscriptionTier {
        await refreshCurrentTierState().tier
    }

    func currentSubscriptionSnapshot() async -> SubscriptionAccessSnapshot? {
        nil
    }

    func refreshCurrentSubscriptionSnapshot() async -> SubscriptionAccessSnapshot? {
        nil
    }

    func startMonitoring() {}
}

final class SubscriptionAccessService: SubscriptionAccessServicing, @unchecked Sendable {
    private enum Constants {
        static let regularTier = "REGULAR"
    }

    private let subscriptionService: SubscriptionAccessContractServicing
    private let userProfileStorageService: UserProfileStorageServiceProtocol
    private let notificationCenter: NotificationCenter
    private let currentDate: @Sendable () -> Date
    private let state = State()
    private let monitoringState = MonitoringState()

    private var logoutObserver: NSObjectProtocol?

    init(
        subscriptionService: SubscriptionAccessContractServicing,
        userProfileStorageService: UserProfileStorageServiceProtocol,
        notificationCenter: NotificationCenter = .default,
        currentDate: @escaping @Sendable () -> Date = Date.init
    ) {
        self.subscriptionService = subscriptionService
        self.userProfileStorageService = userProfileStorageService
        self.notificationCenter = notificationCenter
        self.currentDate = currentDate

        logoutObserver = notificationCenter.addObserver(
            forName: .authSessionDidLogout,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.clearCachedState()
            }
        }
    }

    deinit {
        if let logoutObserver {
            notificationCenter.removeObserver(logoutObserver)
        }

        let monitoringState = self.monitoringState
        Task {
            await monitoringState.cancelAll()
        }
    }

    func currentTierState() async -> SubscriptionTierState {
        guard let context = currentUserContext() else {
            await clearCachedState()
            return .resolved(.regular)
        }

        guard let snapshot = await resolvedCurrentSubscriptionSnapshot(for: context) else {
            return .unavailable
        }

        return .resolved(snapshot.tier)
    }

    func refreshCurrentTierState() async -> SubscriptionTierState {
        await refreshCurrentTierSourceState().tierState
    }

    func refreshCurrentTierSourceState() async -> SubscriptionTierRefreshState {
        guard let context = currentUserContext() else {
            await clearCachedState()
            return .unavailable
        }

        return await resolvedRefreshedSubscriptionState(
            for: context,
            fallbackSnapshot: await cachedSnapshot(for: context)
        )
        .tierRefreshState
    }

    func currentSubscriptionSnapshot() async -> SubscriptionAccessSnapshot? {
        guard let context = currentUserContext() else {
            await clearCachedState()
            return nil
        }

        return await resolvedCurrentSubscriptionSnapshot(for: context)
    }

    func refreshCurrentSubscriptionSnapshot() async -> SubscriptionAccessSnapshot? {
        guard let context = currentUserContext() else {
            await clearCachedState()
            return nil
        }

        return await resolvedRefreshedSubscriptionState(
            for: context,
            fallbackSnapshot: await cachedSnapshot(for: context)
        )
        .snapshot
    }

    func startMonitoring() {
        Task { [weak self] in
            guard let self,
                  await monitoringState.beginMonitoringIfNeeded() else {
                return
            }

            let notificationsTask = Task<Void, Never> { [weak self] in
                guard let self else {
                    return
                }

                await self.observeMonitoringNotifications()
            }
            await monitoringState.setNotificationsTask(notificationsTask)

            _ = await refreshCurrentTierSourceState()
        }
    }
}

private extension SubscriptionAccessService {
    struct UserContext {
        let userID: String
        let profile: UserProfileDefaults
    }

    func currentUserContext() -> UserContext? {
        guard let profile = userProfileStorageService.loadProfile() else {
            return nil
        }

        let userID = profile.userId
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !userID.isEmpty else {
            return nil
        }

        return UserContext(
            userID: userID,
            profile: profile
        )
    }

    func resolvedCurrentSubscriptionSnapshot(
        for context: UserContext
    ) async -> SubscriptionAccessSnapshot? {
        if let cachedSnapshot = await cachedSnapshot(for: context) {
            if shouldRefresh(for: cachedSnapshot) {
                return await resolvedRefreshedSubscriptionState(
                    for: context,
                    fallbackSnapshot: cachedSnapshot
                )
                .snapshot
            }

            await scheduleRefreshIfNeeded(for: cachedSnapshot)
            return cachedSnapshot
        }

        do {
            let snapshot = try await subscriptionService.getSubscription()
            return await resolveAcceptedRefreshState(
                from: snapshot,
                for: context,
                fallbackSnapshot: nil
            )
            .snapshot
        } catch {
            return nil
        }
    }

    func resolvedRefreshedSubscriptionState(
        for context: UserContext,
        fallbackSnapshot: SubscriptionAccessSnapshot?
    ) async -> SubscriptionAccessRefreshState {
        do {
            let snapshot = try await subscriptionService.refreshSubscription()
            return await resolveAcceptedRefreshState(
                from: snapshot,
                for: context,
                fallbackSnapshot: fallbackSnapshot
            )
        } catch {
            if let fallbackSnapshot {
                await scheduleRefreshIfNeeded(for: fallbackSnapshot)
                return .cache(fallbackSnapshot)
            }

            return .unavailable
        }
    }

    func resolveAcceptedRefreshState(
        from snapshot: SubscriptionAccessSnapshot,
        for context: UserContext,
        fallbackSnapshot: SubscriptionAccessSnapshot?
    ) async -> SubscriptionAccessRefreshState {
        let localSnapshot: SubscriptionAccessSnapshot?
        if let fallbackSnapshot {
            localSnapshot = fallbackSnapshot
        } else {
            localSnapshot = await cachedSnapshot(for: context)
        }

        if let localSnapshot,
           snapshot.statusVersion < localSnapshot.statusVersion {
            await state.setSnapshot(localSnapshot, for: context.userID)
            await scheduleRefreshIfNeeded(for: localSnapshot)
            return .cache(localSnapshot)
        }

        await state.setSnapshot(snapshot, for: context.userID)
        persistSnapshot(snapshot, for: context)
        await scheduleRefreshIfNeeded(for: snapshot)
        return .network(snapshot)
    }

    func cachedSnapshot(for context: UserContext) async -> SubscriptionAccessSnapshot? {
        if let cachedSnapshot = await state.snapshot(for: context.userID) {
            return cachedSnapshot
        }

        if let storedSnapshot = context.profile.cachedSubscription {
            await state.setSnapshot(storedSnapshot, for: context.userID)
            return storedSnapshot
        }

        return nil
    }

    func persistSnapshot(
        _ snapshot: SubscriptionAccessSnapshot,
        for context: UserContext
    ) {
        guard let latestProfile = userProfileStorageService.loadProfile(),
              latestProfile.userId == context.userID else {
            return
        }

        userProfileStorageService.saveProfile(
            latestProfile.withCachedSubscription(snapshot)
        )
    }

    func shouldRefresh(for snapshot: SubscriptionAccessSnapshot) -> Bool {
        guard let paidAccessUntil = snapshot.paidAccessUntil else {
            return false
        }

        return currentDate() >= paidAccessUntil
    }

    func scheduleRefreshIfNeeded(for snapshot: SubscriptionAccessSnapshot) async {
        guard let paidAccessUntil = snapshot.paidAccessUntil else {
            await monitoringState.cancelExpiryRefreshTask()
            return
        }

        let delay = paidAccessUntil.timeIntervalSince(currentDate())
        guard delay > .zero else {
            await monitoringState.cancelExpiryRefreshTask()
            return
        }

        let refreshTask = Task { [weak self] in
            let nanoseconds = UInt64(delay * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanoseconds)

            guard !Task.isCancelled else {
                return
            }

            _ = await self?.refreshCurrentTierSourceState()
        }

        await monitoringState.setExpiryRefreshTask(refreshTask)
    }

    func observeMonitoringNotifications() async {
        for await _ in notificationCenter.notifications(named: UIApplication.willEnterForegroundNotification) {
            guard !Task.isCancelled else {
                return
            }

            _ = await refreshCurrentTierSourceState()
        }
    }

    func clearCachedState() async {
        await state.clear()
        await monitoringState.cancelExpiryRefreshTask()
    }
}

private extension SubscriptionAccessService {
    actor State {
        private var userID: String?
        private var snapshot: SubscriptionAccessSnapshot?

        func snapshot(for userID: String) -> SubscriptionAccessSnapshot? {
            guard self.userID == userID else {
                return nil
            }

            return snapshot
        }

        func setSnapshot(_ snapshot: SubscriptionAccessSnapshot, for userID: String) {
            self.userID = userID
            self.snapshot = snapshot
        }

        func clear() {
            userID = nil
            snapshot = nil
        }
    }

    actor MonitoringState {
        private var isMonitoringStarted = false
        private var notificationsTask: Task<Void, Never>?
        private var expiryRefreshTask: Task<Void, Never>?

        func beginMonitoringIfNeeded() -> Bool {
            guard !isMonitoringStarted else {
                return false
            }

            isMonitoringStarted = true
            return true
        }

        func setNotificationsTask(_ task: Task<Void, Never>) {
            notificationsTask = task
        }

        func setExpiryRefreshTask(_ task: Task<Void, Never>) {
            expiryRefreshTask?.cancel()
            expiryRefreshTask = task
        }

        func cancelExpiryRefreshTask() {
            expiryRefreshTask?.cancel()
            expiryRefreshTask = nil
        }

        func cancelAll() {
            notificationsTask?.cancel()
            notificationsTask = nil
            cancelExpiryRefreshTask()
            isMonitoringStarted = false
        }
    }
}
