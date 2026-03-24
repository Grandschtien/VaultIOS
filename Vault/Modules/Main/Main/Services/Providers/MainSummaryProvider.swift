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

    init(summaryService: MainSummaryContractServicing) {
        self.summaryService = summaryService
    }

    func fetchSummary() async throws -> MainSummaryModel {
        let summary = try await summaryService.getSummary(parameters: .init())

        return MainSummaryModel(
            totalAmount: summary.total,
            currency: summary.currency,
            changePercent: .zero
        )
    }
}
