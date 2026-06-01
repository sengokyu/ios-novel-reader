import XCTest
@testable import Tundokuko

final class EpisodeListParserTests: XCTestCase {
    let parser = EpisodeListParser()

    func testParsesEpisodeCount() throws {
        let result = try parser.parse(html: novelTopHTML())
        XCTAssertEqual(result.episodes.count, 3)
    }

    func testParsesEpisodeIndexes() throws {
        let result = try parser.parse(html: novelTopHTML())
        XCTAssertEqual(result.episodes.map(\.index), [1, 2, 3])
    }

    func testParsesEpisodeTitles() throws {
        let result = try parser.parse(html: novelTopHTML())
        XCTAssertEqual(result.episodes[0].title, "第一話\u{3000}はじまり")
        XCTAssertEqual(result.episodes[1].title, "第二話\u{3000}つづき")
    }

    func testReturnsEmptyForNoEpisodes() throws {
        let result = try parser.parse(html: "<html><body></body></html>")
        XCTAssertTrue(result.episodes.isEmpty)
    }

    func testNoNextPageWhenPagerAbsent() throws {
        let result = try parser.parse(html: novelTopHTML())
        XCTAssertNil(result.nextPageHref)
    }

    func testDetectsNextPageHref() throws {
        let html = """
        <html><body>
        <a class="p-eplist__subtitle" href="/n0000aa/1/">第一話</a>
        <a class="c-pager__item--next" href="?p=2">次へ</a>
        </body></html>
        """
        let result = try parser.parse(html: html)
        XCTAssertEqual(result.nextPageHref, "?p=2")
    }
}
