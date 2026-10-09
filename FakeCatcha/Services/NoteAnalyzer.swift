import UIKit
import CoreImage

/// Runs the full screening pipeline on a still image.
final class NoteAnalyzer {
    private let ciContext: CIContext

    init(ciContext: CIContext = CIContext(options: [.cacheIntermediates: false])) {
        self.ciContext = ciContext
    }

    func analyze(_ image: UIImage) async -> AnalysisReport {
        let context = ciContext
        return await Task.detached(priority: .userInitiated) {
            NoteAnalyzer.runAnalysis(on: image, ciContext: context)
        }.value
    }

    static func runAnalysis(on image: UIImage, ciContext: CIContext) -> AnalysisReport {
        guard let input = ImageUtilities.uprightCIImage(from: image) else {
            let failure = CheckResult(.noteDetection, .fail, summary: "Couldn't read the image.")
            return AnalysisReport(originalImage: image, noteImage: nil, denomination: nil, serialNumber: nil, checks: [failure])
        }

        // 1. Find and flatten the note.
        let detection = NoteDetector().detect(in: input)
        let note = detection.noteImage

        // 2. OCR. The flattened note may be upside down, so also read it rotated 180°
        //    when the first pass finds neither a value nor a serial number.
        let recognizer = TextRecognizer()
        var texts = recognizer.recognize(in: note)
        if !containsUsefulText(texts) {
            texts += recognizer.recognize(in: ImageUtilities.movedToOrigin(note.oriented(.down)))
        }

        // 3. Pixel statistics.
        let sample = PixelSample.render(note, targetWidth: 192, context: ciContext)
        let detailSample = PixelSample.render(note, targetWidth: 900, context: ciContext)
        let colour = sample.map { ColourAnalysis(sample: $0) }

        let context = AnalysisContext(detection: detection,
                                      texts: texts,
                                      sample: sample,
                                      detailSample: detailSample,
                                      colour: colour,
                                      currentYear: Calendar.current.component(.year, from: Date()))

        // 4. Checks.
        var checks: [CheckResult] = []
        checks.append(NoteDetectionCheck().evaluate(context, denomination: nil))

        let denominationOutcome = DenominationCheck().evaluate(context)
        let denomination = denominationOutcome.denomination
        checks.append(denominationOutcome.result)

        checks.append(AspectRatioCheck().evaluate(context, denomination: denomination))
        checks.append(ColourProfileCheck().evaluate(context, denomination: denomination))

        let serialOutcome = SerialNumberCheck().evaluate(context, denomination: denomination)
        checks.append(serialOutcome.result)

        checks.append(ClearWindowCheck().evaluate(context, denomination: denomination))
        checks.append(PrintSharpnessCheck().evaluate(context, denomination: denomination))

        let preview = ImageUtilities.uiImage(from: note, context: ciContext)
        return AnalysisReport(originalImage: image,
                              noteImage: preview,
                              denomination: denomination,
                              serialNumber: serialOutcome.serial,
                              checks: checks)
    }

    private static func containsUsefulText(_ texts: [RecognizedText]) -> Bool {
        DenominationCheck.ocrDenomination(in: texts) != nil
            || SerialNumberParser.bestSerial(in: texts.flatMap { $0.candidates }) != nil
    }
}
