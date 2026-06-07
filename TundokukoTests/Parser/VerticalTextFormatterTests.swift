import XCTest
@testable import Tundokuko

final class VerticalTextFormatterTests: XCTestCase {
    let formatter = VerticalTextFormatter()

    func testFullwidthExclamationQuestion() {
        XCTAssertEqual(formatter.format("えっ！？"), "えっ⁉︎")
    }

    func testFullwidthQuestionExclamation() {
        XCTAssertEqual(formatter.format("なに？！"), "なに⁈︎")
    }

    func testFullwidthDoubleExclamation() {
        XCTAssertEqual(formatter.format("すごい！！"), "すごい‼︎")
    }

    func testFullwidthDoubleQuestion() {
        XCTAssertEqual(formatter.format("え？？"), "え⁇︎")
    }

    func testAsciiExclamationQuestion() {
        XCTAssertEqual(formatter.format("!?"), "⁉︎")
    }

    func testAsciiDoubleExclamation() {
        XCTAssertEqual(formatter.format("!!"), "‼︎")
    }

    func testPreservesHtmlTags() {
        XCTAssertEqual(formatter.format("<p>えっ！？</p>"), "<p>えっ⁉︎</p>")
    }

    func testPreservesUnaffectedText() {
        let text = "<p>通常のテキスト。</p>"
        XCTAssertEqual(formatter.format(text), text)
    }

    func testMultipleOccurrences() {
        XCTAssertEqual(formatter.format("！？テキスト！？"), "⁉︎テキスト⁉︎")
    }

    // MARK: - Isolated half-width alphanumeric → full-width

    func testIsolatedLetterConverted() {
        XCTAssertEqual(formatter.format("第A巻"), "第Ａ巻")
    }

    func testIsolatedDigitConverted() {
        XCTAssertEqual(formatter.format("第1章"), "第１章")
    }

    func testIsolatedLowercaseConverted() {
        XCTAssertEqual(formatter.format("x軸"), "ｘ軸")
    }

    func testSequentialAlphanumericPreserved() {
        XCTAssertEqual(formatter.format("iPhone"), "iPhone")
    }

    func testMultiDigitNumberPreserved() {
        XCTAssertEqual(formatter.format("12話"), "12話")
    }

    func testHtmlTagCharsNotConverted() {
        // 'p', 'r', 'u', 'b', 'y' etc. inside tags must not be touched
        XCTAssertEqual(formatter.format("<p>A</p>"), "<p>Ａ</p>")
        XCTAssertEqual(formatter.format("<ruby>A<rt>えい</rt></ruby>"), "<ruby>Ａ<rt>えい</rt></ruby>")
    }

    func testIsolatedAlphanumericInHtmlText() {
        XCTAssertEqual(formatter.format("<p>彼はA組だ</p>"), "<p>彼はＡ組だ</p>")
    }
}
