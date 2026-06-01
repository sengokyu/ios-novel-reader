import Foundation
import GRDB

struct Novel: Sendable, Codable {
    var id: Int64?
    var url: String
    var title: String
    var author: String
    var synopsis: String
    var totalEpisodes: Int
    var updatedAt: Date
    var datePublished: String?
}

extension Novel: FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "novels"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
