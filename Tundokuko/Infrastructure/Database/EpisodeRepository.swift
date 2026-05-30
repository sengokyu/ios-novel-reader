import GRDB

struct EpisodeRepository {
    let dbQueue: DatabaseQueue

    func fetchAll(novelId: Int64) async throws -> [Episode] {
        try await dbQueue.read { db in
            try Episode
                .filter(Column("novelId") == novelId)
                .order(Column("index"))
                .fetchAll(db)
        }
    }

    func fetchOne(id: Int64) async throws -> Episode? {
        try await dbQueue.read { db in
            try Episode.fetchOne(db, key: id)
        }
    }

    func save(_ episode: inout Episode) async throws {
        try await dbQueue.write { db in
            try episode.save(db)
        }
    }

    func saveAll(_ episodes: inout [Episode]) async throws {
        try await dbQueue.write { db in
            for i in episodes.indices {
                try episodes[i].save(db)
            }
        }
    }

    func delete(id: Int64) async throws {
        _ = try await dbQueue.write { db in
            try Episode.deleteOne(db, key: id)
        }
    }

    func deleteAll(novelId: Int64) async throws {
        _ = try await dbQueue.write { db in
            try Episode
                .filter(Column("novelId") == novelId)
                .deleteAll(db)
        }
    }

    func storageSizeBytes(novelId: Int64) async throws -> Int64 {
        try await dbQueue.read { db in
            let sql = "SELECT COALESCE(SUM(LENGTH(content)), 0) FROM episodes WHERE novelId = ? AND content IS NOT NULL"
            return try Int64.fetchOne(db, sql: sql, arguments: [novelId]) ?? 0
        }
    }

    func totalStorageSizeBytes() async throws -> Int64 {
        try await dbQueue.read { db in
            let sql = "SELECT COALESCE(SUM(LENGTH(content)), 0) FROM episodes WHERE content IS NOT NULL"
            return try Int64.fetchOne(db, sql: sql) ?? 0
        }
    }

    func fetchedCount(novelId: Int64) async throws -> Int {
        try await dbQueue.read { db in
            try Episode
                .filter(sql: "novelId = ? AND content IS NOT NULL", arguments: [novelId])
                .fetchCount(db)
        }
    }
}
