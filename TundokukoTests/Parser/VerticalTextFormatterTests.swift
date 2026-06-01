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
}
