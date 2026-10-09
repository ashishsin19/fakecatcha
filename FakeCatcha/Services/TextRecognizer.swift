import CoreImage
import Vision

struct RecognizedText {
    /// Best candidate followed by alternatives, most confident first.
    let candidates: [String]
    let confidence: Float
    /// Normalised bounding box (Vision coordinates, origin bottom-left).
    let boundingBox: CGRect

    var string: String { candidates.first ?? "" }
}

/// On-device OCR using Vision's VNRecognizeTextRequest.
struct TextRecognizer {
    func recognize(in image: CIImage) -> [RecognizedText] {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        request.recognitionLanguages = ["en-US"]

        let handler = VNImageRequestHandler(ciImage: image, options: [:])
        do {
            try handler.perform([request])
        } catch {
            return []
        }
        let observations = request.results ?? []
        return observations.compactMap { observation in
            let top = observation.topCandidates(3)
            guard let first = top.first else { return nil }
            return RecognizedText(candidates: top.map { $0.string },
                                  confidence: first.confidence,
                                  boundingBox: observation.boundingBox)
        }
    }
}
