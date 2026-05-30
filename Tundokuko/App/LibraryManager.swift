import Foundation

enum LibraryError: Error, LocalizedError {
    case unsupportedSite
    case invalidEncoding

    var errorDescription: String? {
        switch self {
        case .unsupportedSite: "対応していないサイトです"
        case .invalidEncoding: "ページの文字コードを読み取れませんでした"
        }
    }
}

actor LibraryManager {
    private static let appGroupID = "group.cc.sengokyu.Tundokuko"
    static let pendingURLKey = "pendingNovelURL"

    private let httpClient = HTTPClient()
    private let novelRepository: NovelRepository
    private let episodeRepository: EpisodeRepository
    private let adapters: [any SiteAdapter] = [NarouAdapter()]

    init(dbClient: DatabaseClient) {
        novelRepository = NovelRepository(dbQueue: dbClient.dbQueue)
        episodeRepository = EpisodeRepository(dbQueue: dbClient.dbQueue)
    }

    // Reads the URL left by Share Extension and registers the novel
    func processPendingURL() async throws {
        guard
            let defaults = UserDefaults(suiteName: Self.appGroupID),
            let urlString = defaults.string(forKey: Self.pendingURLKey),
            let url = URL(string: urlString)
        else { return }

        defaults.removeObject(forKey: Self.pendingURLKey)
        try await registerNovel(from: url)
    }

    func registerNovel(from url: URL) async throws {
        guard let adapter = adapters.first(where: { $0.canHandle(url: url) }) else {
            throw LibraryError.unsupportedSite
        }

        let topURL = adapter.novelTopURL(from: url)

        let topData = try await httpClient.fetch(topURL)
        guard let topHTML = String(data: topData, encoding: .utf8) else {
            throw LibraryError.invalidEncoding
        }

        let info = try NovelInfoParser().parse(html: topHTML)
        let episodeRefs = try EpisodeListParser().parse(html: topHTML)

        var novel = try await upsertNovel(info: info, episodeCount: episodeRefs.count, url: topURL)
        guard let novelId = novel.id else { return }

        let existingEpisodes = try await episodeRepository.fetchAll(novelId: novelId)
        let fetchedIndexes = Set(existingEpisodes.filter { $0.content != nil }.map { $0.index })

        for ref in episodeRefs where !fetchedIndexes.contains(ref.index) {
            try await Task.sleep(for: .seconds(1))
            await fetchAndSaveEpisode(
                ref: ref,
                novelId: novelId,
                adapter: adapter,
                topURL: topURL,
                existing: existingEpisodes
            )
        }
    }

    // MARK: - Private

    private func upsertNovel(
        info: NovelInfoParser.Result,
        episodeCount: Int,
        url: URL
    ) async throws -> Novel {
        if var existing = try await novelRepository.fetchOne(url: url.absoluteString) {
            existing.title = info.title
            existing.author = info.author
            existing.synopsis = info.synopsis
            existing.totalEpisodes = episodeCount
            existing.updatedAt = Date()
            try await novelRepository.save(&existing)
            return existing
        }

        var novel = Novel(
            id: nil,
            url: url.absoluteString,
            title: info.title,
            author: info.author,
            synopsis: info.synopsis,
            totalEpisodes: episodeCount,
            updatedAt: Date()
        )
        try await novelRepository.save(&novel)
        return novel
    }

    // Individual episode fetch errors are silently skipped
    private func fetchAndSaveEpisode(
        ref: EpisodeListParser.EpisodeRef,
        novelId: Int64,
        adapter: any SiteAdapter,
        topURL: URL,
        existing: [Episode]
    ) async {
        let epURL = adapter.episodeURL(novelTopURL: topURL, index: ref.index)

        guard
            let epData = try? await httpClient.fetch(epURL),
            let epHTML = String(data: epData, encoding: .utf8)
        else { return }

        let content = try? EpisodeContentParser().parse(html: epHTML)

        var episode = existing.first(where: { $0.index == ref.index }) ?? Episode(
            id: nil,
            novelId: novelId,
            index: ref.index,
            title: ref.title,
            content: nil,
            fetchedAt: nil
        )
        episode.title = ref.title
        episode.content = content
        episode.fetchedAt = content != nil ? Date() : nil

        try? await episodeRepository.save(&episode)
    }
}
