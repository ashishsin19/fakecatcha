import CoreImage
import CoreImage.CIFilterBuiltins
import Vision

/// Locates the banknote in a photo and produces a flattened, landscape image of it.
struct NoteDetector {
    enum Mode {
        /// Vision found the note's outline and it was perspective-corrected.
        case rectangle
        /// No outline found, but the whole photo has banknote proportions, so we assume it is already cropped.
        case assumedCropped
        /// Nothing usable found.
        case notFound
    }

    struct Detection {
        let mode: Mode
        let confidence: Float
        /// Landscape image of the note (or the whole photo when `mode == .notFound`).
        let noteImage: CIImage
    }

    func detect(in image: CIImage) -> Detection {
        let request = VNDetectRectanglesRequest()
        // Vision's aspect ratio is short side / long side. Notes are 0.41-0.50; we accept a wider
        // range so that wrongly sized notes are still found (and then flagged by the ratio check).
        request.minimumAspectRatio = 0.3
        request.maximumAspectRatio = 0.75
        request.minimumSize = 0.2
        request.minimumConfidence = 0.4
        request.quadratureTolerance = 25
        request.maximumObservations = 4

        let handler = VNImageRequestHandler(ciImage: image, options: [:])
        do {
            try handler.perform([request])
        } catch {
            return fallback(for: image)
        }

        let observations = request.results ?? []
        guard let best = observations.max(by: { area(of: $0) < area(of: $1) }) else {
            return fallback(for: image)
        }

        let extent = image.extent
        func point(_ normalized: CGPoint) -> CGPoint {
            CGPoint(x: extent.origin.x + normalized.x * extent.width,
                    y: extent.origin.y + normalized.y * extent.height)
        }

        let filter = CIFilter.perspectiveCorrection()
        filter.inputImage = image
        filter.topLeft = point(best.topLeft)
        filter.topRight = point(best.topRight)
        filter.bottomLeft = point(best.bottomLeft)
        filter.bottomRight = point(best.bottomRight)

        guard let output = filter.outputImage, output.extent.width >= 10, output.extent.height >= 10 else {
            return fallback(for: image)
        }
        let flattened = ImageUtilities.landscape(ImageUtilities.movedToOrigin(output))
        return Detection(mode: .rectangle, confidence: best.confidence, noteImage: flattened)
    }

    private func fallback(for image: CIImage) -> Detection {
        let landscape = ImageUtilities.landscape(image)
        let ratio = landscape.extent.width / max(landscape.extent.height, 1)
        if Denomination.plausibleAspectRange.contains(Double(ratio)) {
            return Detection(mode: .assumedCropped, confidence: 0, noteImage: landscape)
        }
        return Detection(mode: .notFound, confidence: 0, noteImage: landscape)
    }

    private func area(of observation: VNRectangleObservation) -> CGFloat {
        // Shoelace formula on the normalised quadrilateral.
        let p = [observation.topLeft, observation.topRight, observation.bottomRight, observation.bottomLeft]
        var sum: CGFloat = 0
        for i in 0..<4 {
            let a = p[i], b = p[(i + 1) % 4]
            sum += a.x * b.y - b.x * a.y
        }
        return abs(sum) / 2
    }
}
