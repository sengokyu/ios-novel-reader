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

    // Matches HTML tags (to skip) or isolated half-width alphanumeric characters.
    // Group 1 captures the isolated alphanumeric; absent when a tag matched.
    private static let isolatedAlphanumericRegex = try! NSRegularExpression(
        pattern: #"<[^>]+>|(?<![A-Za-z0-9])([A-Za-z0-9])(?![A-Za-z0-9])"#
    )

    func format(_ html: String) -> String {
        let afterPunctuation = Self.punctuationReplacements.reduce(html) { result, pair in
            result.replacingOccurrences(of: pair.0, with: pair.1)
        }
        return convertIsolatedHalfwidth(afterPunctuation)
    }

    // Converts isolated single half-width alphanumeric to full-width (offset 0xFEE0).
    // Characters inside HTML tags are skipped.
    private func convertIsolatedHalfwidth(_ html: String) -> String {
        let regex = Self.isolatedAlphanumericRegex
        var result = ""
        var lastEnd = html.startIndex

        regex.enumerateMatches(in: html, range: NSRange(html.startIndex..., in: html)) { match, _, _ in
            guard let match, let matchRange = Range(match.range, in: html) else { return }

            result += html[lastEnd..<matchRange.lowerBound]

            let group1 = match.range(at: 1)
            if group1.location != NSNotFound,
               let groupRange = Range(group1, in: html),
               let scalar = html[groupRange].unicodeScalars.first {
                // Half-width → full-width: digits/A-Z/a-z all share offset 0xFEE0
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
