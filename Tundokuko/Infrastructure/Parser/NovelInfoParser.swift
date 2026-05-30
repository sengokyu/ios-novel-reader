import SwiftSoup

struct NovelInfoParser {
    struct Result: Sendable {
        var title: String
        var author: String
        var synopsis: String
    }

    func parse(html: String) throws -> Result {
        let doc = try SwiftSoup.parse(html)

        let title = try doc.select(".p-novel__title").first()?.text() ?? ""
        let author = try doc.select(".p-novel__author a").first()?.text() ?? ""
        let synopsis = try doc.select("#novel_ex").first()?.text() ?? ""

        if title.isEmpty {
            throw ParserError.metadataNotFound
        }

        return Result(title: title, author: author, synopsis: synopsis)
    }
}
