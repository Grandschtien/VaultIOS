//
//  MainSummaryProvider.swift
//  Vault
//
//  Created by Егор Шкарин on 24.03.2026.
//

import Foundation

protocol MainSummaryProviding: Sendable {
    func fetchSummary() async throws -> MainSummaryModel
}

final class MainSummaryProvider: MainSummaryProviding {
    private let summaryService: MainSummaryContractServicing
    private let summaryPeriodProvider: MainSummaryPeriodProviding

    init(
        summaryService: MainSummaryContractServicing,
        summaryPeriodProvider: MainSummaryPeriodProviding
    ) {
        self.summaryService = summaryService
        self.summaryPeriodProvider = summaryPeriodProvider
    }

    func fetchSummary() async throws -> MainSummaryModel {
        let period = summaryPeriodProvider.currentMonthPeriod()
        let summary = try await summaryService.getSummary(
            parameters: .init(
                from: period.from,
                to: period.to
            )
        )

        return MainSummaryModel(
            totalAmount: summary.total,
            currency: summary.currency,
            changePercent: .zero
        )
    }
}
