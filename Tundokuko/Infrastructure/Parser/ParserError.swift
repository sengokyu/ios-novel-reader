import Foundation

enum ParserError: Error, LocalizedError {
    case metadataNotFound
    case contentNotFound

    var errorDescription: String? {
        switch self {
        case .metadataNotFound: "作品情報が見つかりませんでした"
        case .contentNotFound: "本文が見つかりませんでした"
        }
    }
}
