import Foundation

/// Extracts Australian polymer banknote serial numbers from OCR output.
///
/// Format (RBA): two prefix letters, two digits giving the year of printing, then a
/// six-digit (first polymer series) or seven-digit (later printings) number,
/// e.g. "DB 99 572038" or "AA 23 1234567".
enum SerialNumberParser {
    private static let regex: NSRegularExpression = {
        let pattern = "(?<![A-Z0-9])([A-Z0-9]{2})\\s?([0-9OQDILSBZG]{2})\\s?([0-9OQDILSBZG]{6,7})(?![A-Z0-9])"
        // The pattern is a constant, so this cannot fail at runtime.
        return try! NSRegularExpression(pattern: pattern)
    }()

    private static let toLetter: [Character: Character] = ["0": "O", "1": "I", "2": "Z", "5": "S", "6": "G", "8": "B"]
    private static let toDigit: [Character: Character] = ["O": "0", "Q": "0", "D": "0", "I": "1", "L": "1",
                                                          "S": "5", "B": "8", "Z": "2", "G": "6"]

    /// Returns the best serial number candidate found in `text`, if any.
    static func parse(_ text: String) -> SerialNumber? {
        candidates(in: text).max { $0.rawDigitCount < $1.rawDigitCount }
    }

    /// Returns the best serial number candidate across many OCR strings.
    static func bestSerial(in texts: [String]) -> SerialNumber? {
        texts.flatMap { candidates(in: $0) }.max { $0.rawDigitCount < $1.rawDigitCount }
    }

    static func candidates(in text: String) -> [SerialNumber] {
        let upper = text.uppercased()
        let range = NSRange(upper.startIndex..<upper.endIndex, in: upper)
        var results: [SerialNumber] = []
        for match in regex.matches(in: upper, options: [], range: range) {
            guard match.numberOfRanges == 4,
                  let prefixRange = Range(match.range(at: 1), in: upper),
                  let yearRange = Range(match.range(at: 2), in: upper),
                  let numberRange = Range(match.range(at: 3), in: upper) else { continue }

            let rawPrefix = String(upper[prefixRange])
            let rawYear = String(upper[yearRange])
            let rawNumber = String(upper[numberRange])

            let prefix = String(rawPrefix.map { toLetter[$0] ?? $0 })
            guard prefix.allSatisfy({ $0.isASCII && $0.isLetter }) else { continue }

            let digitsPart = rawYear + rawNumber
            let realDigits = digitsPart.filter { $0.isASCII && $0.isNumber }.count
            // Require most of the numeric part to be genuine digits so that ordinary words don't match.
            guard realDigits * 2 >= digitsPart.count + 1 else { continue }

            let yearDigits = String(rawYear.map { toDigit[$0] ?? $0 })
            let number = String(rawNumber.map { toDigit[$0] ?? $0 })
            guard let yy = Int(yearDigits), number.allSatisfy({ $0.isASCII && $0.isNumber }) else { continue }

            let year = yy >= 88 ? 1900 + yy : 2000 + yy
            results.append(SerialNumber(prefix: prefix, year: year, number: number, rawDigitCount: realDigits))
        }
        return results
    }
}
