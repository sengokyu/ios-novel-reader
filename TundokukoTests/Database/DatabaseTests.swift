import XCTest
import GRDB
@testable import Tundokuko

final class DatabaseTests: XCTestCase {
    var dbQueue: DatabaseQueue!
    var novelRepo: NovelRepository!
    var episodeRepo: EpisodeRepository!
    var positionRepo: ReadingPositionRepository!

    override func setUpWithError() throws {
        dbQueue = try DatabaseQueue()
        try DatabaseClient.migrate(dbQueue)
        novelRepo = NovelRepository(dbQueue: dbQueue)
        episodeRepo = EpisodeRepository(dbQueue: dbQueue)
        positionRepo = ReadingPositionRepository(dbQueue: dbQueue)
    }

    func testSaveAndFetchNovel() async throws {
        var novel = Novel(id: nil, url: "https://example.com/n0001/",
                         title: "テスト小説", author: "作者", synopsis: "あらすじ",
                         totalEpisodes: 3, updatedAt: Date())
        try await novelRepo.save(&novel)

        XCTAssertNotNil(novel.id)
        let fetched = try await novelRepo.fetchAll()
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched[0].title, "テスト小説")
    }

    func testFetchNovelByURL() async throws {
        var novel = Novel(id: nil, url: "https://example.com/n0002/",
                         title: "URL検索テスト", author: "作者", synopsis: "",
                         totalEpisodes: 1, updatedAt: Date())
        try await novelRepo.save(&novel)

        let found = try await novelRepo.fetchOne(url: "https://example.com/n0002/")
        XCTAssertEqual(found?.title, "URL検索テスト")

        let notFound = try await novelRepo.fetchOne(url: "https://example.com/missing/")
        XCTAssertNil(notFound)
    }

    func testDeleteNovelCascadesToEpisodes() async throws {
        var novel = Novel(id: nil, url: "https://example.com/n0003/",
                         title: "削除テスト", author: "作者", synopsis: "",
                         totalEpisodes: 1, updatedAt: Date())
        try await novelRepo.save(&novel)
        let novelId = try XCTUnwrap(novel.id)

        var episode = Episode(id: nil, novelId: novelId, index: 1,
                             title: "第一話", content: "本文", fetchedAt: Date())
        try await episodeRepo.save(&episode)

        try await novelRepo.delete(id: novelId)

        let episodes = try await episodeRepo.fetchAll(novelId: novelId)
        XCTAssertTrue(episodes.isEmpty)
    }

    func testSaveAndFetchReadingPosition() async throws {
        var novel = Novel(id: nil, url: "https://example.com/n0004/",
                         title: "位置保存テスト", author: "作者", synopsis: "",
                         totalEpisodes: 1, updatedAt: Date())
        try await novelRepo.save(&novel)
        let novelId = try XCTUnwrap(novel.id)

        var episode = Episode(id: nil, novelId: novelId, index: 1,
                             title: "第一話", content: nil, fetchedAt: nil)
        try await episodeRepo.save(&episode)
        let episodeId = try XCTUnwrap(episode.id)

        let position = ReadingPosition(novelId: novelId, episodeId: episodeId, pageOffset: 1234.5)
        try await positionRepo.save(position)

        let fetched = try await positionRepo.fetch(novelId: novelId)
        XCTAssertEqual(fetched?.pageOffset, 1234.5)
        XCTAssertEqual(fetched?.episodeId, episodeId)
    }

    func testStorageSizeCalculation() async throws {
        var novel = Novel(id: nil, url: "https://example.com/n0005/",
                         title: "容量テスト", author: "作者", synopsis: "",
                         totalEpisodes: 2, updatedAt: Date())
        try await novelRepo.save(&novel)
        let novelId = try XCTUnwrap(novel.id)

        let content = String(repeating: "あ", count: 100)
        var ep1 = Episode(id: nil, novelId: novelId, index: 1,
                         title: "第一話", content: content, fetchedAt: Date())
        var ep2 = Episode(id: nil, novelId: novelId, index: 2,
                         title: "第二話", content: nil, fetchedAt: nil)
        try await episodeRepo.save(&ep1)
        try await episodeRepo.save(&ep2)

        let size = try await episodeRepo.storageSizeBytes(novelId: novelId)
        XCTAssertGreaterThan(size, 0)

        let fetchedCount = try await episodeRepo.fetchedCount(novelId: novelId)
        XCTAssertEqual(fetchedCount, 1)
    }
}
