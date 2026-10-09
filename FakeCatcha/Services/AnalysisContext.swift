import CoreImage

/// Everything the individual checks need, computed once per scan.
struct AnalysisContext {
    let detection: NoteDetector.Detection
    let texts: [RecognizedText]
    /// ~192 px wide sample of the flattened note, for colour and region statistics.
    let sample: PixelSample?
    /// ~900 px wide sample of the flattened note, for sharpness.
    let detailSample: PixelSample?
    let colour: ColourAnalysis?
    let currentYear: Int

    var note: CIImage { detection.noteImage }

    var noteBoundsKnown: Bool { detection.mode != .notFound }

    /// Long side / short side of the flattened note.
    var measuredAspectRatio: Double? {
        guard noteBoundsKnown else { return nil }
        let extent = note.extent
        let longSide = max(extent.width, extent.height)
        let shortSide = min(extent.width, extent.height)
        guard shortSide > 0 else { return nil }
        return Double(longSide / shortSide)
    }

    /// All OCR strings including alternatives.
    var allStrings: [String] { texts.flatMap { $0.candidates } }
}

/// A single heuristic check.
protocol NoteCheck {
    var kind: CheckKind { get }
    func evaluate(_ context: AnalysisContext, denomination: Denomination?) -> CheckResult
}
