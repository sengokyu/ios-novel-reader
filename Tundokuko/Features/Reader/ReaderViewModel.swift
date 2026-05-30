import Foundation

@Observable
@MainActor
final class ReaderViewModel {
    private(set) var episode: Episode?
    private(set) var isLoading = false
    var errorMessage: String?

    private let novel: Novel
    private let episodeRepository: EpisodeRepository
    private let positionRepository: ReadingPositionRepository
    private var currentScrollOffset: Double = 0

    lazy var controller: ReaderController = {
        let c = ReaderController()
        c.onScrollChanged = { [weak self] offset in
            self?.currentScrollOffset = offset
        }
        return c
    }()

    init(novel: Novel, dbClient: DatabaseClient) {
        self.novel = novel
        episodeRepository = EpisodeRepository(dbQueue: dbClient.dbQueue)
        positionRepository = ReadingPositionRepository(dbQueue: dbClient.dbQueue)
    }

    func load(episodeId: Int64) async {
        isLoading = true
        defer { isLoading = false }
        do {
            guard let ep = try await episodeRepository.fetchOne(id: episodeId) else { return }
            episode = ep

            var savedPosition: ReadingPosition?
            if let novelId = novel.id {
                savedPosition = try await positionRepository.fetch(novelId: novelId)
            }
            let offset: Double? = savedPosition?.episodeId == episodeId ? savedPosition?.pageOffset : nil

            controller.setContent(ep.content ?? "", offset: offset)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func savePosition() async {
        guard let ep = episode, let epId = ep.id, let novelId = novel.id else { return }
        let pos = ReadingPosition(novelId: novelId, episodeId: epId, pageOffset: currentScrollOffset)
        try? await positionRepository.save(pos)
    }
}
