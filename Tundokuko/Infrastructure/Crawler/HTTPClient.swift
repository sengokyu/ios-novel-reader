import Foundation

enum HTTPError: Error, LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: "無効なレスポンスです"
        case .httpError(let code): "HTTPエラー: \(code)"
        }
    }
}

struct HTTPClient: Sendable {
    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = ["User-Agent": "Tundokuko/0.1"]
        config.timeoutIntervalForRequest = 30
        session = URLSession(configuration: config)
    }

    init(session: URLSession) {
        self.session = session
    }

    func fetch(_ url: URL) async throws -> Data {
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse else {
            throw HTTPError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw HTTPError.httpError(statusCode: http.statusCode)
        }
        return data
    }
}
