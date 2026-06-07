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

    func processPendingURL() async throws {
        guard
            let defaults = UserDefaults(suiteName: Self.appGroupID),
            let urlString = defaults.string(forKey: Self.pendingURLKey),
            let url = URL(string: urlString)
        else { return }

        defaults.removeObject(forKey: Self.pendingURLKey)
        try await registerNovel(from: url)
    }

    // Fetches and saves episode index only; does not download episode content.
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
        let episodeRefs = try await fetchAllEpisodeRefs(firstPageHTML: topHTML, baseURL: topURL)

        let novel = try await upsertNovel(info: info, episodeCount: episodeRefs.count, url: topURL)
        guard let novelId = novel.id else { return }

        try await upsertEpisodeStubs(refs: episodeRefs, novelId: novelId)
    }

    // Downloads and saves content for a single episode.
    func fetchEpisodeContent(_ episode: Episode, novelURL: String) async throws -> Episode {
        guard
            let url = URL(string: novelURL),
            let adapter = adapters.first(where: { $0.canHandle(url: url) })
        else { throw LibraryError.unsupportedSite }

        let epURL = adapter.episodeURL(novelTopURL: url, index: episode.index)
        let data = try await httpClient.fetch(epURL)
        guard let html = String(data: data, encoding: .utf8) else {
            throw LibraryError.invalidEncoding
        }

        let content = try EpisodeContentParser().parse(html: html)
        var updated = episode
        updated.content = content
        updated.fetchedAt = Date()
        return try await episodeRepository.save(updated)
    }

    // MARK: - Private

    private func fetchAllEpisodeRefs(firstPageHTML: String, baseURL: URL) async throws -> [EpisodeListParser.EpisodeRef] {
        var allRefs: [EpisodeListParser.EpisodeRef] = []
        var html = firstPageHTML
        var currentURL = baseURL

        while true {
            let result = try EpisodeListParser().parse(html: html)
            allRefs.append(contentsOf: result.episodes)

            guard
                let nextHref = result.nextPageHref,
                let nextURL = URL(string: nextHref, relativeTo: currentURL)?.absoluteURL
            else { break }

            try await Task.sleep(for: .seconds(1))
            let data = try await httpClient.fetch(nextURL)
            guard let nextHTML = String(data: data, encoding: .utf8) else { break }

            html = nextHTML
            currentURL = nextURL
        }

        return allRefs
    }

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
            existing.datePublished = info.datePublished
            return try await novelRepository.save(existing)
        }

        let novel = Novel(
            id: nil,
            url: url.absoluteString,
            title: info.title,
            author: info.author,
            synopsis: info.synopsis,
            totalEpisodes: episodeCount,
            updatedAt: Date(),
            datePublished: info.datePublished
        )
        return try await novelRepository.save(novel)
    }

    // Saves episode stubs for all refs. Preserves content of already-downloaded episodes.
    private func upsertEpisodeStubs(refs: [EpisodeListParser.EpisodeRef], novelId: Int64) async throws {
        let existing = try await episodeRepository.fetchAll(novelId: novelId)
        let existingByIndex = Dictionary(uniqueKeysWithValues: existing.map { ($0.index, $0) })

        var toSave: [Episode] = []
        for ref in refs {
            if var ep = existingByIndex[ref.index] {
                ep.title = ref.title
                toSave.append(ep)
            } else {
                toSave.append(Episode(
                    id: nil,
                    novelId: novelId,
                    index: ref.index,
                    title: ref.title,
                    content: nil,
                    fetchedAt: nil
                ))
            }
        }
        try await episodeRepository.saveAll(toSave)
    }
}
