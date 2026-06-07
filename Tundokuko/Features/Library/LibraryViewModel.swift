import Foundation

@Observable
@MainActor
final class LibraryViewModel {
    private(set) var novels: [Novel] = []
    private(set) var fetchedCounts: [Int64: Int] = [:]
    private(set) var storageSizes: [Int64: Int64] = [:]
    private(set) var totalStorageBytes: Int64 = 0
    private(set) var isLoading = false
    var errorMessage: String?

    let libraryManager: LibraryManager
    private let novelRepository: NovelRepository
    private let episodeRepository: EpisodeRepository
    let dbClient: DatabaseClient

    init(dbClient: DatabaseClient, libraryManager: LibraryManager) {
        self.dbClient = dbClient
        self.libraryManager = libraryManager
        novelRepository = NovelRepository(dbQueue: dbClient.dbQueue)
        episodeRepository = EpisodeRepository(dbQueue: dbClient.dbQueue)
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            novels = try await novelRepository.fetchAll()
            totalStorageBytes = try await episodeRepository.totalStorageSizeBytes()
            var counts: [Int64: Int] = [:]
            var sizes: [Int64: Int64] = [:]
            for novel in novels {
                guard let id = novel.id else { continue }
                counts[id] = try await episodeRepository.fetchedCount(novelId: id)
                sizes[id] = try await episodeRepository.storageSizeBytes(novelId: id)
            }
            fetchedCounts = counts
            storageSizes = sizes
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(novel: Novel) async {
        guard let id = novel.id else { return }
        do {
            try await novelRepository.delete(id: id)
            novels.removeAll { $0.id == id }
            fetchedCounts.removeValue(forKey: id)
            storageSizes.removeValue(forKey: id)
            totalStorageBytes = try await episodeRepository.totalStorageSizeBytes()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func processPendingURL() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await libraryManager.processPendingURL()
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
