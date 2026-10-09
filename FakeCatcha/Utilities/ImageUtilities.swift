import UIKit
import CoreImage
import ImageIO

extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}

enum ImageUtilities {
    /// Converts a UIImage to an upright CIImage with its origin at (0, 0),
    /// downscaled so that its longest side is at most `maxDimension` pixels.
    static func uprightCIImage(from image: UIImage, maxDimension: CGFloat = 2400) -> CIImage? {
        var ciImage: CIImage
        if let cgImage = image.cgImage {
            ciImage = CIImage(cgImage: cgImage).oriented(CGImagePropertyOrientation(image.imageOrientation))
        } else if let ci = image.ciImage {
            ciImage = ci
        } else {
            return nil
        }
        ciImage = movedToOrigin(ciImage)

        let longest = max(ciImage.extent.width, ciImage.extent.height)
        if longest > maxDimension, longest > 0 {
            let scale = maxDimension / longest
            ciImage = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
            ciImage = movedToOrigin(ciImage)
        }
        return ciImage
    }

    static func movedToOrigin(_ image: CIImage) -> CIImage {
        let extent = image.extent
        return image.transformed(by: CGAffineTransform(translationX: -extent.origin.x, y: -extent.origin.y))
    }

    /// Rotates the image so that its long side is horizontal.
    static func landscape(_ image: CIImage) -> CIImage {
        let extent = image.extent
        guard extent.height > extent.width else { return image }
        return movedToOrigin(image.oriented(.left))
    }

    static func uiImage(from image: CIImage, context: CIContext) -> UIImage? {
        guard let cgImage = context.createCGImage(image, from: image.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
