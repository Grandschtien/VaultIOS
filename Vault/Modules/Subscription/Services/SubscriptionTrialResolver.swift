import Foundation
import RevenueCat

enum SubscriptionTrialResolver {
    static func resolveTrialText(
        from discount: SubscriptionRevenueCatDiscount?,
        eligibility: IntroEligibilityStatus
    ) -> String? {
        guard eligibility == .eligible,
              let discount,
              discount.paymentMode == .freeTrial,
              let periodText = makePeriodText(from: discount.subscriptionPeriod) else {
            return nil
        }

        return L10n.subscriptionTrialFreeFor(periodText)
    }
}

private extension SubscriptionTrialResolver {
    static func makePeriodText(from period: SubscriptionPeriod) -> String? {
        switch period.unit {
        case .day:
            return period.value == 1
                ? L10n.subscriptionTrialPeriodDay(period.value)
                : L10n.subscriptionTrialPeriodDays(period.value)
        case .week:
            return period.value == 1
                ? L10n.subscriptionTrialPeriodWeek(period.value)
                : L10n.subscriptionTrialPeriodWeeks(period.value)
        case .month:
            return period.value == 1
                ? L10n.subscriptionTrialPeriodMonth(period.value)
                : L10n.subscriptionTrialPeriodMonths(period.value)
        case .year:
            return period.value == 1
                ? L10n.subscriptionTrialPeriodYear(period.value)
                : L10n.subscriptionTrialPeriodYears(period.value)
        @unknown default:
            return nil
        }
    }
}
