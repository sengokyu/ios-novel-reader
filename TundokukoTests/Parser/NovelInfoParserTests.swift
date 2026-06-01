import XCTest
@testable import Tundokuko

final class NovelInfoParserTests: XCTestCase {
    let parser = NovelInfoParser()

    func testParsesTitle() throws {
        let result = try parser.parse(html: novelTopHTML())
        XCTAssertEqual(result.title, "テスト小説タイトル")
    }

    func testParsesAuthor() throws {
        let result = try parser.parse(html: novelTopHTML())
        XCTAssertEqual(result.author, "テスト作者名")
    }

    func testParsesSynopsis() throws {
        let result = try parser.parse(html: novelTopHTML())
        XCTAssertTrue(result.synopsis.contains("あらすじ"))
    }

    func testParsesDatePublished() throws {
        let result = try parser.parse(html: novelTopHTML())
        XCTAssertNotNil(result.datePublished)
        XCTAssertTrue(result.datePublished!.contains("2024/03/15"))
    }

    func testDatePublishedIsNilWhenAbsent() throws {
        let result = try parser.parse(html: "<html><body><p class=\"p-novel__title\">タイトル</p></body></html>")
        XCTAssertNil(result.datePublished)
    }

    func testThrowsWhenTitleMissing() {
        XCTAssertThrowsError(try parser.parse(html: "<html><body></body></html>"))
    }
}
