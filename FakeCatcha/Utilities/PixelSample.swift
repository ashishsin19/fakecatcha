import CoreImage
import Foundation

/// A small RGBA8 bitmap rendered from a CIImage so that pixel statistics can be
/// computed in plain Swift.
struct PixelSample {
    let width: Int
    let height: Int
    /// RGBA, 4 bytes per pixel, row-major.
    let bytes: [UInt8]

    init(width: Int, height: Int, bytes: [UInt8]) {
        self.width = width
        self.height = height
        self.bytes = bytes
    }

    /// Renders `image` scaled to `targetWidth` pixels wide (aspect ratio preserved).
    static func render(_ image: CIImage, targetWidth: Int, context: CIContext) -> PixelSample? {
        let extent = image.extent
        guard extent.width >= 1, extent.height >= 1, !extent.isInfinite, targetWidth > 0 else { return nil }
        let width = targetWidth
        let height = max(1, Int((extent.height * CGFloat(width) / extent.width).rounded()))
        let scaleX = CGFloat(width) / extent.width
        let scaleY = CGFloat(height) / extent.height
        let scaled = image
            .transformed(by: CGAffineTransform(translationX: -extent.origin.x, y: -extent.origin.y))
            .transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        bytes.withUnsafeMutableBytes { buffer in
            guard let base = buffer.baseAddress else { return }
            context.render(scaled,
                           toBitmap: base,
                           rowBytes: width * 4,
                           bounds: CGRect(x: 0, y: 0, width: width, height: height),
                           format: .RGBA8,
                           colorSpace: colorSpace)
        }
        return PixelSample(width: width, height: height, bytes: bytes)
    }

    /// RGB components in 0...1.
    func rgb(x: Int, y: Int) -> (r: Double, g: Double, b: Double) {
        let i = (y * width + x) * 4
        return (Double(bytes[i]) / 255.0, Double(bytes[i + 1]) / 255.0, Double(bytes[i + 2]) / 255.0)
    }

    /// Luma in 0...255.
    func luma(x: Int, y: Int) -> Double {
        let i = (y * width + x) * 4
        return 0.299 * Double(bytes[i]) + 0.587 * Double(bytes[i + 1]) + 0.114 * Double(bytes[i + 2])
    }

    /// Whole-image luma buffer in 0...255.
    func lumaBuffer() -> [Double] {
        var out = [Double](repeating: 0, count: width * height)
        for y in 0..<height {
            for x in 0..<width {
                out[y * width + x] = luma(x: x, y: y)
            }
        }
        return out
    }
}

enum ColourMath {
    /// Converts RGB (0...1) to HSV with hue in degrees (0..<360) and saturation/value in 0...1.
    static func hsv(r: Double, g: Double, b: Double) -> (h: Double, s: Double, v: Double) {
        let maxC = max(r, g, b)
        let minC = min(r, g, b)
        let delta = maxC - minC
        var hue: Double = 0
        if delta > 0.000_01 {
            if maxC == r {
                hue = 60 * ((g - b) / delta).truncatingRemainder(dividingBy: 6)
            } else if maxC == g {
                hue = 60 * ((b - r) / delta + 2)
            } else {
                hue = 60 * ((r - g) / delta + 4)
            }
        }
        if hue < 0 { hue += 360 }
        let saturation = maxC <= 0 ? 0 : delta / maxC
        return (hue, saturation, maxC)
    }

    static func distance(_ a: (r: Double, g: Double, b: Double), _ b: (r: Double, g: Double, b: Double)) -> Double {
        let dr = a.r - b.r, dg = a.g - b.g, db = a.b - b.b
        return (dr * dr + dg * dg + db * db).squareRoot()
    }

    static func median(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        let sorted = values.sorted()
        let mid = sorted.count / 2
        return sorted.count % 2 == 0 ? (sorted[mid - 1] + sorted[mid]) / 2 : sorted[mid]
    }
}
