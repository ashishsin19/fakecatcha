import Foundation

struct NoteDetectionCheck: NoteCheck {
    let kind = CheckKind.noteDetection

    func evaluate(_ context: AnalysisContext, denomination: Denomination?) -> CheckResult {
        switch context.detection.mode {
        case .rectangle:
            let confidence = Int((context.detection.confidence * 100).rounded())
            return CheckResult(kind, .pass,
                               summary: "Note outline found and flattened.",
                               detail: "Vision rectangle confidence \(confidence)%.")
        case .assumedCropped:
            return CheckResult(kind, .warn,
                               summary: "No outline found – assuming the photo is cropped to the note.",
                               detail: "For best results, photograph the whole note on a plain, contrasting background.")
        case .notFound:
            return CheckResult(kind, .fail,
                               summary: "Couldn't find a banknote-shaped outline.",
                               detail: "Lay the note flat on a plain, contrasting surface with all four corners visible, and avoid glare.")
        }
    }
}
