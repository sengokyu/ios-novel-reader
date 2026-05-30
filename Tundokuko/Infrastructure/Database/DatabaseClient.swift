import Foundation
import GRDB

final class DatabaseClient: @unchecked Sendable {
    let dbQueue: DatabaseQueue

    init() throws {
        let path = try Self.databasePath()
        dbQueue = try DatabaseQueue(path: path)
        try Self.migrate(dbQueue)
    }

    private static func databasePath() throws -> String {
        let folder = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return folder.appendingPathComponent("tundokuko.sqlite").path
    }

    static func migrate(_ dbQueue: DatabaseQueue) throws {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1") { db in
            try db.create(table: "novels") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("url", .text).notNull().unique()
                t.column("title", .text).notNull()
                t.column("author", .text).notNull()
                t.column("synopsis", .text).notNull()
                t.column("totalEpisodes", .integer).notNull()
                t.column("updatedAt", .datetime).notNull()
            }

            try db.create(table: "episodes") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("novelId", .integer).notNull()
                    .references("novels", onDelete: .cascade)
                t.column("index", .integer).notNull()
                t.column("title", .text).notNull()
                t.column("content", .text)
                t.column("fetchedAt", .datetime)
                t.uniqueKey(["novelId", "index"])
            }

            try db.create(table: "reading_positions") { t in
                t.column("novelId", .integer).notNull().primaryKey()
                    .references("novels", onDelete: .cascade)
                t.column("episodeId", .integer).notNull()
                    .references("episodes", onDelete: .cascade)
                t.column("pageOffset", .double).notNull()
            }
        }

        try migrator.migrate(dbQueue)
    }
}
