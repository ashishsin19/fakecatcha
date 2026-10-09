import XCTest
@testable import FakeCatcha

final class DenominationAndScoreTests: XCTestCase {
    func testOfficialAspectRatios() {
        XCTAssertEqual(Denomination.five.aspectRatio, 130.0 / 65.0, accuracy: 0.0001)
        XCTAssertEqual(Denomination.hundred.aspectRatio, 158.0 / 65.0, accuracy: 0.0001)
    }

    func testNearestDenominationByAspectRatio() {
        XCTAssertEqual(Denomination.nearest(toAspectRatio: 2.0), .five)
        XCTAssertEqual(Denomination.nearest(toAspectRatio: 2.22), .twenty)
        XCTAssertEqual(Denomination.nearest(toAspectRatio: 2.45), .hundred)
    }

    func testHueRanges() {
        XCTAssertTrue(Denomination.ten.hueMatches(215))
        XCTAssertTrue(Denomination.twenty.hueMatches(355))
        XCTAssertTrue(Denomination.twenty.hueMatches(10))
        XCTAssertTrue(Denomination.fifty.hueMatches(50))
        XCTAssertTrue(Denomination.hundred.hueMatches(140))
        XCTAssertFalse(Denomination.ten.hueMatches(50))
    }

    func testOCRVotesPreferLargeExactNumerals() {
        let texts = [
            RecognizedText(candidates: ["50"], confidence: 0.9, boundingBox: CGRect(x: 0, y: 0, width: 0.2, height: 0.3)),
            RecognizedText(candidates: ["FIFTY DOLLARS"], confidence: 0.9, boundingBox: CGRect(x: 0, y: 0, width: 0.3, height: 0.05)),
            RecognizedText(candidates: ["1995"], confidence: 0.9, boundingBox: CGRect(x: 0, y: 0, width: 0.1, height: 0.02))
        ]
        XCTAssertEqual(DenominationCheck.ocrDenomination(in: texts), .fifty)
    }

    func testScoreAndVerdict() {
        let allPass = CheckKind.allCases.map { CheckResult($0, .pass, summary: "") }
        XCTAssertEqual(ScoreCalculator.score(for: allPass), 100)
        XCTAssertEqual(ScoreCalculator.verdict(for: allPass), .noObviousIssues)

        let twoFails = [
            CheckResult(.noteDetection, .pass, summary: ""),
            CheckResult(.denomination, .fail, summary: ""),
            CheckResult(.aspectRatio, .fail, summary: ""),
            CheckResult(.clearWindow, .pass, summary: "")
        ]
        XCTAssertEqual(ScoreCalculator.verdict(for: twoFails), .suspicious)

        let unreadable = [CheckResult(.noteDetection, .fail, summary: "")]
        XCTAssertEqual(ScoreCalculator.verdict(for: unreadable), .unreadable)
    }

    func testSkippedChecksAreExcludedFromScore() {
        let checks = [
            CheckResult(.noteDetection, .pass, summary: ""),
            CheckResult(.serialNumber, .skipped, summary: "")
        ]
        XCTAssertEqual(ScoreCalculator.score(for: checks), 100)
    }

    func testClearWindowBandClassification() {
        var mask = Array(repeating: Array(repeating: false, count: 16), count: 8)
        for row in 0..<8 { mask[row][4] = true }
        XCTAssertEqual(ClearWindowCheck.classify(mask), .verticalBand(columns: 1))

        var small = Array(repeating: Array(repeating: false, count: 16), count: 8)
        small[5][2] = true
        small[5][3] = true
        small[6][2] = true
        XCTAssertEqual(ClearWindowCheck.classify(small), .smallWindow(cells: 3))

        let empty = Array(repeating: Array(repeating: false, count: 16), count: 8)
        XCTAssertEqual(ClearWindowCheck.classify(empty), .notFound)
    }
}
