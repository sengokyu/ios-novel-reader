import Foundation

struct VerticalTextFormatter {
    // VS-15 (U+FE0E) forces text presentation to avoid emoji rendering
    private static let replacements: [(String, String)] = [
        ("！？", "⁉︎"),
        ("？！", "⁈︎"),
        ("！！", "‼︎"),
        ("？？", "⁇︎"),
        ("!?",  "⁉︎"),
        ("?!",  "⁈︎"),
        ("!!",  "‼︎"),
        ("??",  "⁇︎"),
    ]

    func format(_ html: String) -> String {
        Self.replacements.reduce(html) { result, pair in
            result.replacingOccurrences(of: pair.0, with: pair.1)
        }
    }
}
