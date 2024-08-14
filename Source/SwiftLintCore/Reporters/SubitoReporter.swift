/// Reports violations in the custom Subito format.
struct SubitoReporter: Reporter {
    // MARK: - Reporter Conformance

    static let identifier = "subito"
    static let isRealtime = false
    static let description = "Reports violations in the custom Subito format."

    static func generateReport(_ violations: [StyleViolation]) -> String {
        violations
            .group { $0.location.file ?? "Other" }
            .sorted { $0.key < $1.key }
            .map(report)
            .joined(separator: "\n\n")
    }

    /// Generates a report for a single violation.
    ///
    /// - parameter violation: The violation to report.
    ///
    /// - returns: The report for a single violation.
    private static func report(for file: String, with violations: [StyleViolation]) -> String {
        // {emoji} {error,warning}
        //   {full_path_to_file}{:line}{:character}
        //   {content} - {content}
        violations
            .sorted { $0.severity == $1.severity ? $0.location > $1.location : $0.severity > $1.severity }
            .map { violation in
                let emoji, severityColor: String, locationColor = "\u{001B}[0;36m", resetColor = "\u{001B}[0;0m"
                switch violation.severity {
                case .error:
                    emoji = "⛔️"
                    severityColor = "\u{001B}[0;31m"
                case .warning:
                    emoji = "⚠️"
                    severityColor = "\u{001B}[0;33m"
                }
                return """
                \(emoji) \(severityColor)\(violation.severity.rawValue)\(resetColor)
                  \(locationColor)\(violation.location)\(resetColor)
                  \(violation.ruleName) Violation - \(violation.reason) \(violation.ruleIdentifier)
                """
            }
            .joined(separator: "\n\n")
    }
}
