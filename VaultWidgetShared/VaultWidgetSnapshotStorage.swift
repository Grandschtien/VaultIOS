import Foundation

protocol VylokWidgetSnapshotStoring: Sendable {
    func loadSnapshot() -> VylokWidgetSnapshot?
    func saveSnapshot(_ snapshot: VylokWidgetSnapshot)
    func clearSnapshot()
}

enum VylokWidgetSharedConfiguration {
    static let appGroupIdentifier = "group.com.egor.shkarin.Vault"
    static let snapshotStorageKey = "vault.widget.snapshot"
}

final class VylokWidgetSnapshotStorage: VylokWidgetSnapshotStoring, @unchecked Sendable {
    private struct LegacyVylokWidgetSnapshot: Codable {
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
            ?? UserDefaults(suiteName: VylokWidgetSharedConfiguration.appGroupIdentifier)
            ?? .standard
        self.decoder = decoder
        self.encoder = encoder
    }

    func loadSnapshot() -> VylokWidgetSnapshot? {
        guard let data = userDefaults.data(
            forKey: VylokWidgetSharedConfiguration.snapshotStorageKey
        ) else {
            return nil
        }

        if let snapshot = try? decoder.decode(VylokWidgetSnapshot.self, from: data) {
            return snapshot
        }

        guard let legacySnapshot = try? decoder.decode(LegacyVylokWidgetSnapshot.self, from: data) else {
            return nil
        }

        return VylokWidgetSnapshot(
            entitlementState: .subscribed,
            todayAmount: legacySnapshot.todayAmount,
            todayCurrency: legacySnapshot.todayCurrency,
            monthAmount: legacySnapshot.monthAmount,
            monthCurrency: legacySnapshot.monthCurrency,
            updatedAt: legacySnapshot.updatedAt
        )
    }

    func saveSnapshot(_ snapshot: VylokWidgetSnapshot) {
        guard let data = try? encoder.encode(snapshot) else {
            return
        }

        userDefaults.set(
            data,
            forKey: VylokWidgetSharedConfiguration.snapshotStorageKey
        )
    }

    func clearSnapshot() {
        userDefaults.removeObject(
            forKey: VylokWidgetSharedConfiguration.snapshotStorageKey
        )
    }
}
