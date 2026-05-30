import GRDB

struct ReadingPositionRepository {
    let dbQueue: DatabaseQueue

    func fetch(novelId: Int64) async throws -> ReadingPosition? {
        try await dbQueue.read { db in
            try ReadingPosition.fetchOne(db, key: novelId)
        }
    }

    func save(_ position: ReadingPosition) async throws {
        try await dbQueue.write { db in
            try position.save(db)
        }
    }
}
