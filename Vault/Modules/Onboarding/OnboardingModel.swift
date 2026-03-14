// Created by Egor Shkarin 12.03.2026

import UIKit

struct OnboardingModel: Equatable {
    let image: UIImage
    let title: Label.LabelViewModel
    let subtitle: Label.LabelViewModel
    let pill: PillView.ViewModel
}

extension OnboardingModel {
    static let pages: [OnboardingModel] = [
        .init(
            image: .onboarding1, title: Label.LabelViewModel(
                text: L10n.onboarding1Title,
                font: Typography.typographySemibold32,
                textColor: Asset.Colors.textAndIconPrimary.color,
                alignment: .center,
                numberOfLines: .zero,
                lineBreakMode: .byWordWrapping
            ),
            subtitle: Label.LabelViewModel(
                text: L10n.onboarding1Subtitle,
                font: Typography.typographyRegular16,
                textColor: Asset.Colors.textAndIconSecondary.color,
                alignment: .center,
                numberOfLines: .zero,
                lineBreakMode: .byWordWrapping
            ),
            pill: PillView.ViewModel(
                text: Label.LabelViewModel(
                    text: L10n.aiPowered,
                    font: Typography.typographySemibold12,
                    textColor: .interactiveElemetsPrimary
                ),
                image: .aiUsageLight
            ),
        ),
        .init(
            image: .onboarding2,
            title: Label.LabelViewModel(
                text: L10n.onboarding2Title,
                font: Typography.typographySemibold32,
                textColor: Asset.Colors.textAndIconPrimary.color,
                alignment: .center,
                numberOfLines: .zero,
                lineBreakMode: .byWordWrapping
            ),
            subtitle: Label.LabelViewModel(
                text: L10n.onboarding2Subtitle,
                font: Typography.typographyRegular16,
                textColor: Asset.Colors.textAndIconSecondary.color,
                alignment: .center,
                numberOfLines: .zero,
                lineBreakMode: .byWordWrapping
            ),
            pill: PillView.ViewModel(
                text: Label.LabelViewModel(
                    text: L10n.aiSmartEntry,
                    font: Typography.typographySemibold12,
                    textColor: .interactiveElemetsPrimary
                ),
                image: .aiUsageLight
            )
        ),
        .init(
            image: .onboarding3,
            title: Label.LabelViewModel(
                text: L10n.onboarding3Title,
                font: Typography.typographySemibold32,
                textColor: Asset.Colors.textAndIconPrimary.color,
                alignment: .center,
                numberOfLines: .zero,
                lineBreakMode: .byWordWrapping
            ),
            subtitle: Label.LabelViewModel(
                text: L10n.onboarding3Subtitle,
                font: Typography.typographyRegular16,
                textColor: Asset.Colors.textAndIconSecondary.color,
                alignment: .center,
                numberOfLines: .zero,
                lineBreakMode: .byWordWrapping
            ),
            pill: PillView.ViewModel(
                text: Label.LabelViewModel(
                    text: L10n.insightfulAnalytics,
                    font: Typography.typographySemibold12,
                    textColor: .interactiveElemetsPrimary
                ),
                image: .insights
            )
        )
    ]
}
