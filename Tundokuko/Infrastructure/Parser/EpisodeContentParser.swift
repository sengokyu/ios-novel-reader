import SwiftSoup

struct EpisodeContentParser {
    func parse(html: String) throws -> String {
        let doc = try SwiftSoup.parse(html)
        guard let content = try doc.select(".p-novel__text").first() else {
            throw ParserError.contentNotFound
        }
        return try content.html()
    }
}
