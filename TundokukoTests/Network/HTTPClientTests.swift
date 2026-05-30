import XCTest
@testable import Tundokuko

final class HTTPClientTests: XCTestCase {
    var client: HTTPClient!

    override func setUp() {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        client = HTTPClient(session: URLSession(configuration: config))
    }

    override func tearDown() {
        MockURLProtocol.handler = nil
    }

    func testFetchReturnsDataOnSuccess() async throws {
        let expected = "Hello, World!".data(using: .utf8)!
        MockURLProtocol.handler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200,
                                          httpVersion: nil, headerFields: nil)!
            return (response, expected)
        }

        let url = URL(string: "https://example.com/test")!
        let data = try await client.fetch(url)
        XCTAssertEqual(data, expected)
    }

    func testFetchThrowsOnHTTPError() async throws {
        MockURLProtocol.handler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 404,
                                          httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        let url = URL(string: "https://example.com/notfound")!
        do {
            _ = try await client.fetch(url)
            XCTFail("Expected error not thrown")
        } catch HTTPError.httpError(let code) {
            XCTAssertEqual(code, 404)
        }
    }
}

final class MockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
