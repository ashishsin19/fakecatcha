import XCTest
@testable import FakeCatcha

final class SerialNumberParserTests: XCTestCase {
    func testParsesSevenDigitSerialWithSpaces() {
        let serial = SerialNumberParser.parse("AA 23 1234567")
        XCTAssertEqual(serial?.prefix, "AA")
        XCTAssertEqual(serial?.year, 2023)
        XCTAssertEqual(serial?.number, "1234567")
        XCTAssertEqual(serial?.formatted, "AA 23 1234567")
    }

    func testParsesFirstSeriesSixDigitSerial() {
        let serial = SerialNumberParser.parse("DB 99 572038")
        XCTAssertEqual(serial?.year, 1999)
        XCTAssertEqual(serial?.number, "572038")
    }

    func testParsesSerialWithoutSpaces() {
        XCTAssertEqual(SerialNumberParser.parse("EA191234567")?.normalized, "EA191234567")
    }

    func testCorrectsCommonOCRConfusions() {
        // "8" read for "B" in the prefix and "l" read for "1" in the number.
        let serial = SerialNumberParser.parse("A8 23 l234567")
        XCTAssertEqual(serial?.normalized, "AB231234567")
    }

    func testRejectsOrdinaryText() {
        XCTAssertNil(SerialNumberParser.parse("RESERVE BANK OF AUSTRALIA"))
        XCTAssertNil(SerialNumberParser.parse("This Australian note is legal tender"))
        XCTAssertNil(SerialNumberParser.parse("AA 23 12345"))
    }

    func testFindsSerialInsideLongerLine() {
        XCTAssertEqual(SerialNumberParser.parse("No. GH 16 7654321 ")?.normalized, "GH167654321")
    }
}
