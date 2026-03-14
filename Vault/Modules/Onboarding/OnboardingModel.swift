// Created by Egor Shkarin 12.03.2026

import UIKit

struct OnboardingModel {
    let title: String
    let subtitle: String
    let image: OnboardingViewModel.Image
    let pillText: String
    let pillImage: UIImage
}

extension OnboardingModel {
    static let pages: [OnboardingModel] = [
        .init(
            title: L10n.onboarding1Title,
            subtitle: L10n.onboarding1Subtitle,
            image: .onboarding1,
            pillText: L10n.aiPowered,
            pillImage: Asset.Icons.aiUsageLight.image
        ),
        .init(
            title: L10n.onboarding2Title,
            subtitle: L10n.onboarding2Subtitle,
            image: .onboarding2,
            pillText: L10n.aiSmartEntry,
            pillImage: Asset.Icons.aiUsageLight.image
        ),
        .init(
            title: L10n.onboarding3Title,
            subtitle: L10n.onboarding3Subtitle,
            image: .onboarding3,
            pillText: L10n.insightfulAnalytics,
            pillImage: Asset.Icons.insights.image
        )
    ]
}
