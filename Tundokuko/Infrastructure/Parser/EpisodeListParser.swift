import SwiftSoup

struct EpisodeListParser {
    struct EpisodeRef: Sendable {
        var index: Int
        var title: String
    }

    func parse(html: String) throws -> [EpisodeRef] {
        let doc = try SwiftSoup.parse(html)
        let links = try doc.select(".index_box .novel_sublist2 .subtitle a")

        return try links.compactMap { link in
            let href = try link.attr("href")
            let title = try link.text()
            guard let index = episodeIndex(from: href) else { return nil }
            return EpisodeRef(index: index, title: title)
        }
    }

    // Extracts episode number from href like /n2267be/1/
    private func episodeIndex(from href: String) -> Int? {
        let parts = href.split(separator: "/").filter { !$0.isEmpty }
        guard parts.count >= 2 else { return nil }
        return Int(parts[1])
    }
}
