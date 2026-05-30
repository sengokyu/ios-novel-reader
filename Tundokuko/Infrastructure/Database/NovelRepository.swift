import GRDB

struct NovelRepository {
    let dbQueue: DatabaseQueue

    func fetchAll() async throws -> [Novel] {
        try await dbQueue.read { db in
            try Novel.order(Column("updatedAt").desc).fetchAll(db)
        }
    }

    func fetchOne(id: Int64) async throws -> Novel? {
        try await dbQueue.read { db in
            try Novel.fetchOne(db, key: id)
        }
    }

    func fetchOne(url: String) async throws -> Novel? {
        try await dbQueue.read { db in
            try Novel.filter(Column("url") == url).fetchOne(db)
        }
    }

    func save(_ novel: inout Novel) async throws {
        try await dbQueue.write { db in
            try novel.save(db)
        }
    }

    func delete(id: Int64) async throws {
        _ = try await dbQueue.write { db in
            try Novel.deleteOne(db, key: id)
        }
    }
}
