import Foundation

private extension Int {
    var nonZero: Int? { self == 0 ? nil : self }
}

private extension Double {
    var nonZero: Double? { self == 0 ? nil : self }
}

@Observable
@MainActor
final class ReaderViewModel {
    private(set) var episode: Episode?
    private(set) var isLoading = false
    var errorMessage: String?

    private let novel: Novel
    private let libraryManager: LibraryManager
    private let episodeRepository: EpisodeRepository
    private let positionRepository: ReadingPositionRepository
    private var currentScrollOffset: Double = 0

    @ObservationIgnored
    lazy var controller: ReaderController = {
        let c = ReaderController()
        c.onScrollChanged = { [weak self] offset in
            self?.currentScrollOffset = offset
        }
        return c
    }()

    init(novel: Novel, dbClient: DatabaseClient, libraryManager: LibraryManager) {
        self.novel = novel
        self.libraryManager = libraryManager
        episodeRepository = EpisodeRepository(dbQueue: dbClient.dbQueue)
        positionRepository = ReadingPositionRepository(dbQueue: dbClient.dbQueue)
    }

    func load(episodeId: Int64) async {
        isLoading = true
        defer { isLoading = false }
        do {
            guard var ep = try await episodeRepository.fetchOne(id: episodeId) else { return }

            if ep.content == nil {
                ep = try await libraryManager.fetchEpisodeContent(ep, novelURL: novel.url)
            }

            episode = ep

            var savedPosition: ReadingPosition?
            if let novelId = novel.id {
                savedPosition = try await positionRepository.fetch(novelId: novelId)
            }
            let offset: Double? = savedPosition?.episodeId == episodeId ? savedPosition?.pageOffset : nil

            let defaults = UserDefaults.standard
            controller.applySettings(
                fontSize: defaults.integer(forKey: "readerFontSize").nonZero ?? 18,
                lineHeight: defaults.double(forKey: "readerLineHeight").nonZero ?? 2.0,
                height: defaults.integer(forKey: "readerHeight").nonZero ?? 90,
                width: defaults.integer(forKey: "readerWidth").nonZero ?? 90,
                fontFamily: SettingsView.readerFontFamily
            )
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
