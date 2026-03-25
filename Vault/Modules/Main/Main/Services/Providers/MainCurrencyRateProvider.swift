// Created by Egor Shkarin on 25.03.2026

import Foundation

protocol MainCurrencyRateProviding: Sendable {
    func synchronizeCurrencyRateOnLaunch() async throws
}

final class MainCurrencyRateProvider: MainCurrencyRateProviding, @unchecked Sendable {
    private enum Constants {
        static let cacheLifetime: TimeInterval = 86_400
    }

    enum Error: Swift.Error {
        case missingProfile
    }

    private let currencyRateService: MainCurrencyRateContractServicing
    private let userProfileStorageService: UserProfileStorageServiceProtocol
    private let currentDateProvider: @Sendable () -> Date

    init(
        currencyRateService: MainCurrencyRateContractServicing,
        userProfileStorageService: UserProfileStorageServiceProtocol,
        currentDateProvider: @escaping @Sendable () -> Date = Date.init
    ) {
        self.currencyRateService = currencyRateService
        self.userProfileStorageService = userProfileStorageService
        self.currentDateProvider = currentDateProvider
    }

    func synchronizeCurrencyRateOnLaunch() async throws {
        guard let profile = userProfileStorageService.loadProfile() else {
            throw Error.missingProfile
        }

        let now = currentDateProvider()
        if isCacheFresh(profile: profile, now: now) {
            return
        }

        do {
            let response = try await currencyRateService.getCurrencyRate(currency: profile.currency)
            userProfileStorageService.saveProfile(
                profile.withCurrencyRate(response.rateToUsd, updatedAt: now)
            )
        } catch {
            guard profile.currencyRate != nil else {
                throw error
            }
        }
    }
}

private extension MainCurrencyRateProvider {
    func isCacheFresh(profile: UserProfileDefaults, now: Date) -> Bool {
        guard profile.currencyRate != nil,
              let updatedAt = profile.currencyRateUpdatedAt else {
            return false
        }

        return now.timeIntervalSince(updatedAt) < Constants.cacheLifetime
    }
}
