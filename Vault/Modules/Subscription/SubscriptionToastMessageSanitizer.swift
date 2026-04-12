import Foundation

enum SubscriptionToastMessageSanitizer {
    static func sanitize(_ text: String) -> String {
        let sanitizedText = text
            .replacingOccurrences(
                of: #"\s*\[Environment:[^\]]+\]\s*"#,
                with: "",
                options: .regularExpression
            )
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return sanitizedText.isEmpty ? text : sanitizedText
    }
}
