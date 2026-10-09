import Foundation

struct AspectRatioCheck: NoteCheck {
    let kind = CheckKind.aspectRatio

    func evaluate(_ context: AnalysisContext, denomination: Denomination?) -> CheckResult {
        guard let ratio = context.measuredAspectRatio else {
            return CheckResult(kind, .skipped, summary: "Note outline not available.")
        }
        let measured = String(format: "%.2f", ratio)
        let target = denomination ?? Denomination.nearest(toAspectRatio: ratio)
        let expected = target.aspectRatio
        let deviation = abs(ratio - expected) / expected
        let percent = String(format: "%.1f", deviation * 100)
        let official = "Official \(target.label): \(Int(target.widthMM)) × \(Int(Denomination.heightMM)) mm (ratio \(String(format: "%.2f", expected)))."
        let caveat = context.detection.mode == .rectangle
            ? "Shooting at an angle distorts the ratio slightly; hold the phone parallel to the note."
            : "The note outline was assumed from the photo edges, so this is approximate."

        if deviation <= 0.04 {
            return CheckResult(kind, .pass,
                               summary: "Proportions match a \(target.label) note (\(measured), off by \(percent)%).",
                               detail: "\(official) \(caveat)")
        }
        if deviation <= 0.08 || context.detection.mode != .rectangle {
            return CheckResult(kind, .warn,
                               summary: "Proportions are a little off for a \(target.label) note (\(measured), off by \(percent)%).",
                               detail: "\(official) \(caveat)")
        }
        return CheckResult(kind, .fail,
                           summary: "Proportions don't match a \(target.label) note (\(measured), off by \(percent)%).",
                           detail: "\(official) Genuine notes are cut precisely; a wrong size is a common sign of a counterfeit. \(caveat)")
    }
}
