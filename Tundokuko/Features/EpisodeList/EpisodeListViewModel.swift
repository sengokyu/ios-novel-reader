import Foundation

@Observable
@MainActor
final class EpisodeListViewModel {
    private(set) var episodes: [Episode] = []
    private(set) var isLoading = false
    private(set) var isUpdating = false
    private(set) var fetchProgress: LibraryManager.FetchProgress?
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
        fetchProgress = nil
        defer {
            isUpdating = false
            fetchProgress = nil
        }
        do {
            try await libraryManager.registerNovel(from: url) { [weak self] progress in
                Task { @MainActor [weak self] in
                    self?.fetchProgress = progress
                }
            }
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
