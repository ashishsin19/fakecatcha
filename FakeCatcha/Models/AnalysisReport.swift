import SwiftUI

enum Verdict {
    case noObviousIssues
    case inconclusive
    case suspicious
    case unreadable

    var title: String {
        switch self {
        case .noObviousIssues: return "No obvious red flags"
        case .inconclusive: return "Inconclusive – check manually"
        case .suspicious: return "Suspicious – check carefully"
        case .unreadable: return "Couldn't read the note"
        }
    }

    var message: String {
        switch self {
        case .noObviousIssues:
            return "The automated checks didn't find anything unusual. This does not prove the note is genuine – still feel the polymer and check the clear window and tilt features."
        case .inconclusive:
            return "Some checks raised warnings. Re-scan in good, even light on a plain background, then check the security features by hand."
        case .suspicious:
            return "Several checks failed. Compare the note with one you know is genuine and follow the RBA's counterfeit guidance. If you believe it is counterfeit, contact your local police."
        case .unreadable:
            return "Place the whole note flat on a plain, contrasting background and make sure all four corners are visible."
        }
    }

    var color: Color {
        switch self {
        case .noObviousIssues: return .green
        case .inconclusive: return .orange
        case .suspicious: return .red
        case .unreadable: return .gray
        }
    }

    var symbolName: String {
        switch self {
        case .noObviousIssues: return "checkmark.seal.fill"
        case .inconclusive: return "questionmark.diamond.fill"
        case .suspicious: return "exclamationmark.octagon.fill"
        case .unreadable: return "viewfinder"
        }
    }
}

struct AnalysisReport: Identifiable {
    let id = UUID()
    let date = Date()
    let originalImage: UIImage
    let noteImage: UIImage?
    let denomination: Denomination?
    let serialNumber: SerialNumber?
    let checks: [CheckResult]

    var score: Int { ScoreCalculator.score(for: checks) }
    var verdict: Verdict { ScoreCalculator.verdict(for: checks) }
}
