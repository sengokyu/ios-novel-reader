import XCTest
@testable import Tundokuko

final class EpisodeListParserTests: XCTestCase {
    let parser = EpisodeListParser()

    func testParsesEpisodeCount() throws {
        let refs = try parser.parse(html: novelTopHTML())
        XCTAssertEqual(refs.count, 3)
    }

    func testParsesEpisodeIndexes() throws {
        let refs = try parser.parse(html: novelTopHTML())
        XCTAssertEqual(refs.map(\.index), [1, 2, 3])
    }

    func testParsesEpisodeTitles() throws {
        let refs = try parser.parse(html: novelTopHTML())
        XCTAssertEqual(refs[0].title, "第一話\u{3000}はじまり")
        XCTAssertEqual(refs[1].title, "第二話\u{3000}つづき")
    }

    func testReturnsEmptyForNoEpisodes() throws {
        let refs = try parser.parse(html: "<html><body></body></html>")
        XCTAssertTrue(refs.isEmpty)
    }
}
