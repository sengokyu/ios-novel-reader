import XCTest
@testable import Tundokuko

final class EpisodeContentParserTests: XCTestCase {
    let parser = EpisodeContentParser()

    func testReturnsHonbunContent() throws {
        let content = try parser.parse(html: episodeHTML())
        XCTAssertTrue(content.contains("本文一行目"))
    }

    func testPreservesRubyTags() throws {
        let content = try parser.parse(html: episodeHTML())
        XCTAssertTrue(content.contains("<ruby>"))
        XCTAssertTrue(content.contains("<rt>"))
    }

    func testThrowsWhenHonbunMissing() {
        XCTAssertThrowsError(try parser.parse(html: "<html><body></body></html>"))
    }
}
