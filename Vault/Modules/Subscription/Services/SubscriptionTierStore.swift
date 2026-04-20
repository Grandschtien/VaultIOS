//
//  SubscriptionTierStore.swift
//  Vault
//
//  Created by Егор Шкарин on 21.04.2026.
//

import Foundation

actor SubscriptionTierStore {
    private var currentTier: SubscriptionTier = .none
    private var revision: UInt64 = 0

    func value() -> SubscriptionTier {
        currentTier
    }

    func update(to newTier: SubscriptionTier) -> Bool {
        guard currentTier != newTier else { return false }
        currentTier = newTier
        revision += 1
        return true
    }

    func update(to newTier: SubscriptionTier, revision newRevision: UInt64) -> Bool {
        guard newRevision >= revision else { return false }
        guard currentTier != newTier || newRevision != revision else { return false }

        currentTier = newTier
        revision = newRevision
        return true
    }

    func currentRevision() -> UInt64 {
        revision
    }
}
