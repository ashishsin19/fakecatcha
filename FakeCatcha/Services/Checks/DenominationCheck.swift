import Foundation

/// Determines the denomination from OCR and colour and checks that they agree.
struct DenominationCheck {
    let kind = CheckKind.denomination

    struct Outcome {
        let result: CheckResult
        let denomination: Denomination?
    }

    /// Votes for each denomination from printed numerals and words.
    static func ocrVotes(in texts: [RecognizedText]) -> [Denomination: Double] {
        var votes: [Denomination: Double] = [:]
        for text in texts {
            let upper = text.string.uppercased()
            // Large numerals get more weight than small print.
            let weight = 1.0 + Double(text.boundingBox.height) * 10

            let numberTokens = upper.split { !($0.isASCII && $0.isNumber) }.map(String.init)
            for token in numberTokens {
                if let value = Int(token), let denomination = Denomination(rawValue: value), token.count <= 3 {
                    votes[denomination, default: 0] += weight
                }
            }

            let wordTokens = Set(upper.split { !($0.isASCII && $0.isLetter) }.map(String.init))
            for denomination in Denomination.allCases where !wordTokens.isDisjoint(with: denomination.words) {
                votes[denomination, default: 0] += 2.0
            }
        }
        return votes
    }

    static func ocrDenomination(in texts: [RecognizedText]) -> Denomination? {
        let votes = ocrVotes(in: texts)
        guard let best = votes.max(by: { $0.value < $1.value }) else { return nil }
        return best.key
    }

    func evaluate(_ context: AnalysisContext) -> Outcome {
        let fromText = DenominationCheck.ocrDenomination(in: context.texts)
        let fromColour = context.colour?.bestMatch?.denomination
        let fromSize = context.measuredAspectRatio.map { Denomination.nearest(toAspectRatio: $0) }

        switch (fromText, fromColour) {
        case let (text?, colour?) where text == colour:
            return Outcome(result: CheckResult(kind, .pass,
                                               summary: "Printed value and colour both say \(text.label).",
                                               detail: "Expected colour: \(text.colourName)."),
                           denomination: text)
        case let (text?, colour?):
            return Outcome(result: CheckResult(kind, .fail,
                                               summary: "Printed value reads \(text.label) but the colour looks like a \(colour.label).",
                                               detail: "A \(text.label) note should be predominantly \(text.colourName). Mismatched value and colour is a classic sign of an altered or fake note – but strong coloured lighting can also cause this."),
                           denomination: text)
        case let (text?, nil):
            return Outcome(result: CheckResult(kind, .warn,
                                               summary: "Printed value reads \(text.label); colour was inconclusive.",
                                               detail: "Couldn't confirm the \(text.colourName) colour. Try even, white light."),
                           denomination: text)
        case let (nil, colour?):
            return Outcome(result: CheckResult(kind, .warn,
                                               summary: "Colour suggests \(colour.label); couldn't read the printed value.",
                                               detail: "Make sure the large numerals are in focus and not covered by glare."),
                           denomination: colour)
        case (nil, nil):
            if let size = fromSize {
                return Outcome(result: CheckResult(kind, .warn,
                                                   summary: "Couldn't read the value or colour; size suggests \(size.label).",
                                                   detail: "Size alone is a weak indicator."),
                               denomination: size)
            }
            return Outcome(result: CheckResult(kind, .fail,
                                               summary: "Couldn't determine the denomination.",
                                               detail: "Neither the printed value nor the colour matched an Australian note."),
                           denomination: nil)
        }
    }
}
