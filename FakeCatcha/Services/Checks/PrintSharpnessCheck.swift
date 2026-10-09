import Foundation

/// Variance of the Laplacian as a rough measure of fine print detail.
///
/// The thresholds are uncalibrated estimates. Because a blurry photo produces the
/// same signal as blurry print, this check never fails – it only warns.
struct PrintSharpnessCheck: NoteCheck {
    let kind = CheckKind.printSharpness

    static func laplacianVariance(of sample: PixelSample) -> Double {
        let width = sample.width, height = sample.height
        guard width > 2, height > 2 else { return 0 }
        let luma = sample.lumaBuffer()
        var sum = 0.0, sumSquares = 0.0, count = 0.0
        for y in 1..<(height - 1) {
            for x in 1..<(width - 1) {
                let i = y * width + x
                let value = 4 * luma[i] - luma[i - 1] - luma[i + 1] - luma[i - width] - luma[i + width]
                sum += value
                sumSquares += value * value
                count += 1
            }
        }
        let mean = sum / count
        return sumSquares / count - mean * mean
    }

    func evaluate(_ context: AnalysisContext, denomination: Denomination?) -> CheckResult {
        guard let sample = context.detailSample else {
            return CheckResult(kind, .skipped, summary: "Image unavailable.")
        }
        let variance = PrintSharpnessCheck.laplacianVariance(of: sample)
        let detail = "Detail score \(Int(variance.rounded())). Genuine notes have very fine line work and micro-printing; use a magnifier to confirm."
        if variance >= 80 {
            return CheckResult(kind, .pass, summary: "Fine detail looks crisp.", detail: detail)
        }
        if variance >= 25 {
            return CheckResult(kind, .warn, summary: "Fine detail is somewhat soft.", detail: "Retake the photo steadily and in focus. \(detail)")
        }
        return CheckResult(kind, .warn, summary: "Image is very blurry.", detail: "This could be blurry print or just a blurry photo – retake it in focus. \(detail)")
    }
}
