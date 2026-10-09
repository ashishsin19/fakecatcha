import Foundation

enum ScoreCalculator {
    /// Weighted average of check outcomes, 0-100. Skipped checks are excluded.
    static func score(for checks: [CheckResult]) -> Int {
        var total = 0.0
        var weights = 0.0
        for check in checks {
            guard let value = check.status.scoreValue else { continue }
            total += value * check.kind.weight
            weights += check.kind.weight
        }
        guard weights > 0 else { return 0 }
        return Int((total / weights * 100).rounded())
    }

    static func verdict(for checks: [CheckResult]) -> Verdict {
        if let detection = checks.first(where: { $0.kind == .noteDetection }), detection.status == .fail {
            return .unreadable
        }
        let failures = checks.filter { $0.status == .fail }.count
        let total = score(for: checks)
        if failures >= 2 || total < 55 { return .suspicious }
        if failures == 1 || total < 80 { return .inconclusive }
        return .noObviousIssues
    }
}
