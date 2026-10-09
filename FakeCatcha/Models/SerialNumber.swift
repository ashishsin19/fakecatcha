import Foundation

/// A parsed Australian polymer banknote serial number, e.g. "AA 23 1234567".
struct SerialNumber: Equatable {
    /// Two-letter prefix.
    let prefix: String
    /// Full four-digit year of printing derived from the two-digit year code.
    let year: Int
    /// Six (first series) or seven (later printings) digit suffix.
    let number: String
    /// How many characters in the year + number part were real digits in the OCR output
    /// (as opposed to letters corrected to digits). Used to rank candidates.
    let rawDigitCount: Int

    var yearCode: String { String(format: "%02d", year % 100) }

    var formatted: String { "\(prefix) \(yearCode) \(number)" }

    var normalized: String { "\(prefix)\(yearCode)\(number)" }
}
