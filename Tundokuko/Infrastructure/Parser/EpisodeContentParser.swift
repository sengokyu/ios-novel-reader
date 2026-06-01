import SwiftSoup

struct EpisodeContentParser {
    private static let allowedTags: Set<String> = [
        "p", "br", "ruby", "rt", "rp", "em", "strong", "b", "i", "span"
    ]
    // Content inside these tags is discarded entirely, not rendered as text
    private static let strippedTags: Set<String> = [
        "script", "style", "head", "meta", "link", "iframe", "object", "embed"
    ]

    func parse(html: String) throws -> String {
        let doc = try SwiftSoup.parse(html)
        let sections = try doc.select(".p-novel__text")
        guard !sections.isEmpty() else {
            throw ParserError.contentNotFound
        }
        let content = try sections.array()
            .map { try sanitize($0) }
            .joined()
        return VerticalTextFormatter().format(content)
    }

    private func sanitize(_ element: Element) throws -> String {
        try element.getChildNodes()
            .map { try sanitizeNode($0) }
            .joined()
    }

    private func sanitizeNode(_ node: Node) throws -> String {
        if node is TextNode {
            return try node.outerHtml()
        }
        guard let element = node as? Element else {
            return ""
        }
        let tag = element.tagName().lowercased()
        guard !Self.strippedTags.contains(tag) else {
            return ""
        }
        let children = try element.getChildNodes()
            .map { try sanitizeNode($0) }
            .joined()
        guard Self.allowedTags.contains(tag) else {
            return children
        }
        return tag == "br" ? "<br>" : "<\(tag)>\(children)</\(tag)>"
    }
}
