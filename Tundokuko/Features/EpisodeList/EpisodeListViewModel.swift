import Foundation

@Observable
@MainActor
final class EpisodeListViewModel {
    private(set) var episodes: [Episode] = []
    private(set) var isLoading = false
    private(set) var isUpdating = false
    var errorMessage: String?

    private let novel: Novel
    private let episodeRepository: EpisodeRepository
    private let libraryManager: LibraryManager

    init(novel: Novel, dbClient: DatabaseClient, libraryManager: LibraryManager) {
        self.novel = novel
        self.libraryManager = libraryManager
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

    func update() async {
        guard let url = URL(string: novel.url) else { return }
        isUpdating = true
        defer { isUpdating = false }
        do {
            try await libraryManager.registerNovel(from: url)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
