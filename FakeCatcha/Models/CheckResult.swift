import SwiftUI

enum CheckStatus: String {
    case pass
    case warn
    case fail
    case skipped

    /// Contribution to the confidence score. `nil` means the check is excluded.
    var scoreValue: Double? {
        switch self {
        case .pass: return 1.0
        case .warn: return 0.5
        case .fail: return 0.0
        case .skipped: return nil
        }
    }

    var label: String {
        switch self {
        case .pass: return "Pass"
        case .warn: return "Warning"
        case .fail: return "Fail"
        case .skipped: return "Skipped"
        }
    }

    var symbolName: String {
        switch self {
        case .pass: return "checkmark.circle.fill"
        case .warn: return "exclamationmark.triangle.fill"
        case .fail: return "xmark.octagon.fill"
        case .skipped: return "minus.circle"
        }
    }

    var color: Color {
        switch self {
        case .pass: return .green
        case .warn: return .orange
        case .fail: return .red
        case .skipped: return .gray
        }
    }
}

enum CheckKind: String, CaseIterable, Identifiable {
    case noteDetection
    case aspectRatio
    case denomination
    case serialNumber
    case clearWindow
    case colourProfile
    case printSharpness

    var id: String { rawValue }

    var title: String {
        switch self {
        case .noteDetection: return "Note outline"
        case .aspectRatio: return "Size / aspect ratio"
        case .denomination: return "Denomination consistency"
        case .serialNumber: return "Serial number format"
        case .clearWindow: return "Clear window"
        case .colourProfile: return "Colour profile"
        case .printSharpness: return "Print sharpness"
        }
    }

    /// Relative importance when combining checks into a score.
    var weight: Double {
        switch self {
        case .noteDetection: return 1.0
        case .aspectRatio: return 1.5
        case .denomination: return 2.0
        case .serialNumber: return 2.0
        case .clearWindow: return 2.0
        case .colourProfile: return 1.5
        case .printSharpness: return 0.5
        }
    }

    var explanation: String {
        switch self {
        case .noteDetection:
            return "Finds the four corners of the note with Vision rectangle detection and flattens it with Core Image perspective correction."
        case .aspectRatio:
            return "Compares the flattened note's width-to-height ratio with the official RBA dimensions (65 mm tall; 130, 137, 144, 151 and 158 mm wide for $5 to $100)."
        case .denomination:
            return "Reads the printed value with on-device text recognition and compares it with the note's dominant colour. A mismatch is a strong red flag."
        case .serialNumber:
            return "Looks for a serial number in the RBA format: two letters, two digits for the year of printing, then six or seven digits (e.g. AA 23 1234567)."
        case .clearWindow:
            return "Searches for a region that does not look like printed polymer – the transparent window. Next-generation notes have a top-to-bottom window; first-series notes have a small one."
        case .colourProfile:
            return "Measures how much of the note's saturated colour falls in the expected hue range for its denomination. Photocopies and inkjet fakes are often washed out or off-colour."
        case .printSharpness:
            return "Estimates fine-detail sharpness. Genuine notes carry very fine line work; blurry print can indicate a copy – but a blurry photo can too."
        }
    }
}

struct CheckResult: Identifiable {
    let id = UUID()
    let kind: CheckKind
    let status: CheckStatus
    let summary: String
    let detail: String

    init(_ kind: CheckKind, _ status: CheckStatus, summary: String, detail: String = "") {
        self.kind = kind
        self.status = status
        self.summary = summary
        self.detail = detail
    }
}
