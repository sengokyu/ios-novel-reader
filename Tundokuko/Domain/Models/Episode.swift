import Foundation
import GRDB

struct Episode: Sendable, Codable {
    var id: Int64?
    var novelId: Int64
    var index: Int
    var title: String
    var content: String?
    var fetchedAt: Date?
}

extension Episode: FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "episodes"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
