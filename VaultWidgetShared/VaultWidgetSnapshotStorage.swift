import Foundation

protocol VaultWidgetSnapshotStoring: Sendable {
    func loadSnapshot() -> VaultWidgetSnapshot?
    func saveSnapshot(_ snapshot: VaultWidgetSnapshot)
    func clearSnapshot()
}

enum VaultWidgetSharedConfiguration {
    static let appGroupIdentifier = "group.com.egor.shkarin.Vault"
    static let snapshotStorageKey = "vault.widget.snapshot"
}

final class VaultWidgetSnapshotStorage: VaultWidgetSnapshotStoring, @unchecked Sendable {
    private struct LegacyVaultWidgetSnapshot: Codable {
        let todayAmount: Double
        let todayCurrency: String
        let monthAmount: Double
        let monthCurrency: String
        let updatedAt: Date
    }

    private let userDefaults: UserDefaults
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(
        userDefaults: UserDefaults? = nil,
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder()
    ) {
        self.userDefaults = userDefaults
            ?? UserDefaults(suiteName: VaultWidgetSharedConfiguration.appGroupIdentifier)
            ?? .standard
        self.decoder = decoder
        self.encoder = encoder
    }

    func loadSnapshot() -> VaultWidgetSnapshot? {
        guard let data = userDefaults.data(
            forKey: VaultWidgetSharedConfiguration.snapshotStorageKey
        ) else {
            return nil
        }

        if let snapshot = try? decoder.decode(VaultWidgetSnapshot.self, from: data) {
            return snapshot
        }

        guard let legacySnapshot = try? decoder.decode(LegacyVaultWidgetSnapshot.self, from: data) else {
            return nil
        }

        return VaultWidgetSnapshot(
            entitlementState: .subscribed,
            todayAmount: legacySnapshot.todayAmount,
            todayCurrency: legacySnapshot.todayCurrency,
            monthAmount: legacySnapshot.monthAmount,
            monthCurrency: legacySnapshot.monthCurrency,
            updatedAt: legacySnapshot.updatedAt
        )
    }

    func saveSnapshot(_ snapshot: VaultWidgetSnapshot) {
        guard let data = try? encoder.encode(snapshot) else {
            return
        }

        userDefaults.set(
            data,
            forKey: VaultWidgetSharedConfiguration.snapshotStorageKey
        )
    }

    func clearSnapshot() {
        userDefaults.removeObject(
            forKey: VaultWidgetSharedConfiguration.snapshotStorageKey
        )
    }
}
