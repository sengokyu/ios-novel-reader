import SwiftSoup

struct EpisodeListParser {
    struct Result: Sendable {
        var episodes: [EpisodeRef]
        var nextPageHref: String?
    }

    struct EpisodeRef: Sendable {
        var index: Int
        var title: String
    }

    func parse(html: String) throws -> Result {
        let doc = try SwiftSoup.parse(html)
        let links = try doc.select("a.p-eplist__subtitle")

        let episodes = try links.compactMap { link -> EpisodeRef? in
            let href = try link.attr("href")
            let title = try link.text()
            guard let index = episodeIndex(from: href) else { return nil }
            return EpisodeRef(index: index, title: title)
        }

        let nextPageHref = try doc.select("a.c-pager__item--next").first()?.attr("href")

        return Result(episodes: episodes, nextPageHref: nextPageHref.flatMap { $0.isEmpty ? nil : $0 })
    }

    // Extracts episode number from href like /n2267be/1/
    private func episodeIndex(from href: String) -> Int? {
        let parts = href.split(separator: "/").filter { !$0.isEmpty }
        guard parts.count >= 2 else { return nil }
        return Int(parts[1])
    }
}
