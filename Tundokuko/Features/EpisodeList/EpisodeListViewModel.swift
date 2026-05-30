import Foundation

@Observable
@MainActor
final class EpisodeListViewModel {
    private(set) var episodes: [Episode] = []
    private(set) var isLoading = false
    var errorMessage: String?

    private let novel: Novel
    private let episodeRepository: EpisodeRepository

    init(novel: Novel, dbClient: DatabaseClient) {
        self.novel = novel
        episodeRepository = EpisodeRepository(dbQueue: dbClient.dbQueue)
    }

    func load() async {
        guard let novelId = novel.id else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            episodes = try await episodeRepository.fetchAll(novelId: novelId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
