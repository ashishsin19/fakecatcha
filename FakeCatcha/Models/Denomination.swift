import SwiftUI

/// Australian polymer banknote denominations currently in circulation.
///
/// Dimensions are the official sizes published by the Reserve Bank of Australia.
/// All notes are 65 mm tall; the width grows by 7 mm per denomination.
enum Denomination: Int, CaseIterable, Identifiable, Hashable {
    case five = 5
    case ten = 10
    case twenty = 20
    case fifty = 50
    case hundred = 100

    var id: Int { rawValue }

    var label: String { "$\(rawValue)" }

    static let heightMM: Double = 65

    var widthMM: Double {
        switch self {
        case .five: return 130
        case .ten: return 137
        case .twenty: return 144
        case .fifty: return 151
        case .hundred: return 158
        }
    }

    /// Long side divided by short side.
    var aspectRatio: Double { widthMM / Denomination.heightMM }

    /// Dominant colour family of the note, used for the colour profile heuristic.
    var colourName: String {
        switch self {
        case .five: return "mauve / pink"
        case .ten: return "blue"
        case .twenty: return "red / orange"
        case .fifty: return "yellow / gold"
        case .hundred: return "green"
        }
    }

    /// Hue ranges in degrees (0-360) that represent the note's dominant colour.
    var hueRanges: [ClosedRange<Double>] {
        switch self {
        case .five: return [275...345]
        case .ten: return [185...255]
        case .twenty: return [345...360, 0...28]
        case .fifty: return [36...68]
        case .hundred: return [80...175]
        }
    }

    var displayColor: Color {
        switch self {
        case .five: return Color(red: 0.78, green: 0.45, blue: 0.70)
        case .ten: return Color(red: 0.20, green: 0.45, blue: 0.85)
        case .twenty: return Color(red: 0.85, green: 0.30, blue: 0.20)
        case .fifty: return Color(red: 0.90, green: 0.72, blue: 0.15)
        case .hundred: return Color(red: 0.20, green: 0.62, blue: 0.40)
        }
    }

    /// Words printed on the note that identify the value.
    var words: [String] {
        switch self {
        case .five: return ["FIVE"]
        case .ten: return ["TEN"]
        case .twenty: return ["TWENTY"]
        case .fifty: return ["FIFTY"]
        case .hundred: return ["HUNDRED"]
        }
    }

    /// Year the next-generation (NGB) design of this denomination was issued.
    var nextGenerationIssueYear: Int {
        switch self {
        case .five: return 2016
        case .ten: return 2017
        case .twenty: return 2019
        case .fifty: return 2018
        case .hundred: return 2020
        }
    }

    func hueMatches(_ hue: Double) -> Bool {
        hueRanges.contains { $0.contains(hue) }
    }

    /// The denomination whose official aspect ratio is closest to `ratio`.
    static func nearest(toAspectRatio ratio: Double) -> Denomination {
        allCases.min { abs($0.aspectRatio - ratio) < abs($1.aspectRatio - ratio) } ?? .twenty
    }

    static var plausibleAspectRange: ClosedRange<Double> {
        (Denomination.five.aspectRatio * 0.93)...(Denomination.hundred.aspectRatio * 1.07)
    }
}
