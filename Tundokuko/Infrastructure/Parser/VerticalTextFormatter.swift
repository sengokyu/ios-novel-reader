import Foundation

struct VerticalTextFormatter {
    // VS-15 (U+FE0E) forces text presentation to avoid emoji rendering
    private static let punctuationReplacements: [(String, String)] = [
        ("！？", "⁉︎"),
        ("？！", "⁈︎"),
        ("！！", "‼︎"),
        ("？？", "⁇︎"),
        ("!?",  "⁉︎"),
        ("?!",  "⁈︎"),
        ("!!",  "‼︎"),
        ("??",  "⁇︎"),
    ]

    // Matches HTML tags (to skip), isolated 2-char sequences (group 1),
    // or isolated single chars (group 2). Longer runs are left untouched.
    private static let isolatedAlphanumericRegex = try! NSRegularExpression(
        pattern: #"<[^>]+>|(?<![A-Za-z0-9])([A-Za-z0-9]{2})(?![A-Za-z0-9])|(?<![A-Za-z0-9])([A-Za-z0-9])(?![A-Za-z0-9])"#
    )

    func format(_ html: String) -> String {
        let afterPunctuation = Self.punctuationReplacements.reduce(html) { result, pair in
            result.replacingOccurrences(of: pair.0, with: pair.1)
        }
        return convertIsolatedHalfwidth(afterPunctuation)
    }

    // - Isolated 2-char sequences → <span class="tcy"> for text-combine-upright
    // - Isolated 1-char sequences → full-width (offset 0xFEE0)
    // - HTML tags and longer runs → unchanged
    private func convertIsolatedHalfwidth(_ html: String) -> String {
        let regex = Self.isolatedAlphanumericRegex
        var result = ""
        var lastEnd = html.startIndex

        regex.enumerateMatches(in: html, range: NSRange(html.startIndex..., in: html)) { match, _, _ in
            guard let match, let matchRange = Range(match.range, in: html) else { return }

            result += html[lastEnd..<matchRange.lowerBound]

            if match.range(at: 1).location != NSNotFound,
               let groupRange = Range(match.range(at: 1), in: html) {
                // 2-char isolated sequence → tate-chu-yoko span
                result += #"<span class="tcy">"# + html[groupRange] + "</span>"
            } else if match.range(at: 2).location != NSNotFound,
                      let groupRange = Range(match.range(at: 2), in: html),
                      let scalar = html[groupRange].unicodeScalars.first {
                // 1-char isolated → full-width
                result += String(UnicodeScalar(scalar.value + 0xFEE0)!)
            } else {
                result += html[matchRange] // HTML tag — keep as-is
            }

            lastEnd = matchRange.upperBound
        }

        result += html[lastEnd...]
        return result
    }
}
