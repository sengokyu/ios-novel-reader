import Foundation

struct NarouAdapter: SiteAdapter {
    private static let hosts: Set<String> = ["ncode.syosetu.com", "novel18.syosetu.com"]

    func canHandle(url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        return Self.hosts.contains(host)
    }

    func novelTopURL(from url: URL) -> URL {
        guard let host = url.host, let code = novelCode(from: url) else { return url }
        return URL(string: "https://\(host)/\(code)/")!
    }

    func episodeURL(novelTopURL: URL, index: Int) -> URL {
        URL(string: "\(novelTopURL.absoluteString)\(index)/")!
    }

    // Extracts "n2267be" from paths like /n2267be/ or /n2267be/1/
    private func novelCode(from url: URL) -> String? {
        url.pathComponents.first(where: { $0.hasPrefix("n") && $0.count > 1 })
    }
}
