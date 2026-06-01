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

    func testConcatenatesMultipleSections() throws {
        let content = try parser.parse(html: episodeHTML())
        XCTAssertTrue(content.contains("本文一行目"))
        XCTAssertTrue(content.contains("あとがき一行目"))
    }

    func testStripsScriptTags() throws {
        let html = """
        <div class="p-novel__text">
        <p>正常なテキスト</p>
        <script>alert('xss')</script>
        </div>
        """
        let content = try parser.parse(html: html)
        XCTAssertFalse(content.contains("<script>"))
        XCTAssertFalse(content.contains("alert"))
        XCTAssertTrue(content.contains("正常なテキスト"))
    }

    func testStripsDisallowedAttributes() throws {
        let html = """
        <div class="p-novel__text">
        <p onclick="alert('xss')" class="foo">テキスト</p>
        </div>
        """
        let content = try parser.parse(html: html)
        XCTAssertFalse(content.contains("onclick"))
        XCTAssertFalse(content.contains("class="))
        XCTAssertTrue(content.contains("テキスト"))
    }

    func testStripsDisallowedTagsButKeepsText() throws {
        let html = """
        <div class="p-novel__text">
        <p>通常テキスト<a href="http://example.com">リンク</a>続き</p>
        </div>
        """
        let content = try parser.parse(html: html)
        XCTAssertFalse(content.contains("<a"))
        XCTAssertTrue(content.contains("リンク"))
        XCTAssertTrue(content.contains("続き"))
    }

    func testThrowsWhenHonbunMissing() {
        XCTAssertThrowsError(try parser.parse(html: "<html><body></body></html>"))
    }
}
