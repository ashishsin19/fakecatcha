import Foundation

struct SerialNumberCheck {
    let kind = CheckKind.serialNumber

    struct Outcome {
        let result: CheckResult
        let serial: SerialNumber?
    }

    func evaluate(_ context: AnalysisContext, denomination: Denomination?) -> Outcome {
        guard let serial = SerialNumberParser.bestSerial(in: context.allStrings) else {
            return Outcome(result: CheckResult(kind, .warn,
                                               summary: "No serial number found on this side.",
                                               detail: "Serial numbers are only printed on one side of the note. Scan the other side, keep it in focus and avoid glare."),
                           serial: nil)
        }

        var problems: [String] = []
        var notes: [String] = []
        var status = CheckStatus.pass

        if serial.year < 1988 || serial.year > context.currentYear {
            problems.append("Year code \(serial.yearCode) gives \(serial.year), which isn't a valid printing year.")
            status = .fail
        }

        if serial.number.allSatisfy({ $0 == "0" }) {
            problems.append("The number part is all zeros.")
            status = .fail
        }

        if let second = serial.prefix.dropFirst().first, second > "M" {
            notes.append("Second prefix letter \(second) is outside the usual A–M range (only used for some test print runs).")
            if status == .pass { status = .warn }
        }

        let summary: String
        switch status {
        case .pass: summary = "Serial \(serial.formatted) has a valid format (printed \(serial.year))."
        case .warn: summary = "Serial \(serial.formatted) has an unusual format."
        default: summary = "Serial \(serial.formatted) doesn't look valid."
        }
        let detail = (problems + notes + ["OCR can misread characters; compare with the note itself."]).joined(separator: " ")
        return Outcome(result: CheckResult(kind, status, summary: summary, detail: detail), serial: serial)
    }
}
