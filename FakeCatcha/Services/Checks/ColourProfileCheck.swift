import Foundation

struct ColourProfileCheck: NoteCheck {
    let kind = CheckKind.colourProfile

    func evaluate(_ context: AnalysisContext, denomination: Denomination?) -> CheckResult {
        guard let colour = context.colour else {
            return CheckResult(kind, .skipped, summary: "Colour data unavailable.")
        }
        guard let denomination else {
            return CheckResult(kind, .skipped, summary: "Denomination unknown, so there is no colour to compare against.")
        }

        let match = colour.fraction(for: denomination)
        let percent = Int((match * 100).rounded())
        let saturationPercent = Int((colour.meanSaturation * 100).rounded())
        let detail = "\(percent)% of the clearly coloured area is \(denomination.colourName) (expected for \(denomination.label)). Average saturation \(saturationPercent)%. White balance and coloured lighting affect this check."

        if colour.saturatedFraction < 0.08 || colour.meanSaturation < 0.12 {
            return CheckResult(kind, .warn,
                               summary: "Colours look very washed out.",
                               detail: "Faded or greyish colours can indicate a photocopy – or just poor lighting. \(detail)")
        }
        if match >= 0.35 {
            return CheckResult(kind, .pass, summary: "Colour matches a \(denomination.label) note.", detail: detail)
        }
        if match >= 0.18 {
            return CheckResult(kind, .warn, summary: "Colour only partly matches a \(denomination.label) note.", detail: detail)
        }
        return CheckResult(kind, .fail, summary: "Colour doesn't match a \(denomination.label) note.", detail: detail)
    }
}
