import SwiftSoup

struct EpisodeContentParser {
    // Returns inner HTML of #novel_honbun for rendering in WKWebView
    func parse(html: String) throws -> String {
        let doc = try SwiftSoup.parse(html)
        guard let honbun = try doc.select("#novel_honbun").first() else {
            throw ParserError.contentNotFound
        }
        return try honbun.html()
    }
}
