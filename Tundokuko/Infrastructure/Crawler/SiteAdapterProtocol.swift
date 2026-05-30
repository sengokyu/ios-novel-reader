import Foundation

protocol SiteAdapter: Sendable {
    func canHandle(url: URL) -> Bool
    func novelTopURL(from url: URL) -> URL
    func episodeURL(novelTopURL: URL, index: Int) -> URL
}
