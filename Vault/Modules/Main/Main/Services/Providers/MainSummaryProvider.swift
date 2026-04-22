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
    private let currencyConversionService: UserCurrencyConverting

    init(
        summaryService: MainSummaryContractServicing,
        summaryPeriodProvider: MainSummaryPeriodProviding,
        currencyConversionService: UserCurrencyConverting
    ) {
        self.summaryService = summaryService
        self.summaryPeriodProvider = summaryPeriodProvider
        self.currencyConversionService = currencyConversionService
    }

    func fetchSummary() async throws -> MainSummaryModel {
        let period = summaryPeriodProvider.currentMonthPeriod()
        let summary = try await summaryService.getSummary(
            parameters: .init(
                from: period.from,
                to: period.to
            )
        )
        let displayedAmount = currencyConversionService.convertExpense(
            amount: summary.total,
            currency: summary.currency,
            originalAmount: nil,
            originalCurrency: nil
        )

        return MainSummaryModel(
            totalAmount: displayedAmount.amount,
            currency: displayedAmount.currency,
            changePercent: .zero
        )
    }
}
