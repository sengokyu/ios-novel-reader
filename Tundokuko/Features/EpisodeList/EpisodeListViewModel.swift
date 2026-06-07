import Foundation

@Observable
@MainActor
final class EpisodeListViewModel {
    private(set) var episodes: [Episode] = []
    private(set) var lastReadEpisodeId: Int64?
    private(set) var isLoading = false
    private(set) var isUpdating = false
    private(set) var downloadingEpisodeIds: Set<Int64> = []
    var errorMessage: String?

    private let novel: Novel
    private let episodeRepository: EpisodeRepository
    private let positionRepository: ReadingPositionRepository
    private let libraryManager: LibraryManager

    init(novel: Novel, dbClient: DatabaseClient, libraryManager: LibraryManager) {
        self.novel = novel
        self.libraryManager = libraryManager
        episodeRepository = EpisodeRepository(dbQueue: dbClient.dbQueue)
        positionRepository = ReadingPositionRepository(dbQueue: dbClient.dbQueue)
    }

    func load() async {
        guard let novelId = novel.id else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            async let episodesFetch = episodeRepository.fetchAll(novelId: novelId)
            async let positionFetch = positionRepository.fetch(novelId: novelId)
            episodes = try await episodesFetch
            lastReadEpisodeId = try await positionFetch?.episodeId
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // Updates episode index only; does not download content.
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

    func downloadEpisode(_ episode: Episode) async {
        guard let id = episode.id else { return }
        downloadingEpisodeIds.insert(id)
        defer { downloadingEpisodeIds.remove(id) }
        do {
            let updated = try await libraryManager.fetchEpisodeContent(episode, novelURL: novel.url)
            if let idx = episodes.firstIndex(where: { $0.id == id }) {
                episodes[idx] = updated
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
