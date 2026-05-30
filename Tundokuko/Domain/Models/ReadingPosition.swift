import GRDB

struct ReadingPosition: Sendable, Codable {
    var novelId: Int64
    var episodeId: Int64
    var pageOffset: Double
}

extension ReadingPosition: FetchableRecord, PersistableRecord {
    static let databaseTableName = "reading_positions"
}
