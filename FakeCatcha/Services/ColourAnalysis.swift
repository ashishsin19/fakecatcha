import Foundation

/// Hue statistics of the flattened note, computed once and shared by several checks.
struct ColourAnalysis {
    /// For each denomination: fraction of saturated pixels whose hue falls in that note's colour range.
    let fractions: [Denomination: Double]
    /// Fraction of all sampled pixels that are "saturated" (clearly coloured).
    let saturatedFraction: Double
    let meanSaturation: Double

    init(sample: PixelSample) {
        var counts: [Denomination: Int] = [:]
        var saturated = 0
        var total = 0
        var saturationSum = 0.0

        // Ignore a 6% border, which may contain background if the outline wasn't perfect.
        let insetX = max(1, sample.width * 6 / 100)
        let insetY = max(1, sample.height * 6 / 100)
        if sample.width > insetX * 2, sample.height > insetY * 2 {
            for y in insetY..<(sample.height - insetY) {
                for x in insetX..<(sample.width - insetX) {
                    let c = sample.rgb(x: x, y: y)
                    let hsv = ColourMath.hsv(r: c.r, g: c.g, b: c.b)
                    total += 1
                    saturationSum += hsv.s
                    guard hsv.s > 0.25, hsv.v > 0.25 else { continue }
                    saturated += 1
                    for denomination in Denomination.allCases where denomination.hueMatches(hsv.h) {
                        counts[denomination, default: 0] += 1
                    }
                }
            }
        }

        var fractions: [Denomination: Double] = [:]
        for denomination in Denomination.allCases {
            fractions[denomination] = saturated > 0 ? Double(counts[denomination, default: 0]) / Double(saturated) : 0
        }
        self.fractions = fractions
        self.saturatedFraction = total > 0 ? Double(saturated) / Double(total) : 0
        self.meanSaturation = total > 0 ? saturationSum / Double(total) : 0
    }

    func fraction(for denomination: Denomination) -> Double {
        fractions[denomination] ?? 0
    }

    /// The denomination whose colour dominates, if it is reasonably clear.
    var bestMatch: (denomination: Denomination, fraction: Double)? {
        guard saturatedFraction > 0.05,
              let best = fractions.max(by: { $0.value < $1.value }),
              best.value >= 0.25 else { return nil }
        return (best.key, best.value)
    }
}
