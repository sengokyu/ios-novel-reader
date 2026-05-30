//
//  TundokukoApp.swift
//  Tundokuko
//
//  Created by ziyi on R 8/05/30.
//

import SwiftUI

@main
struct TundokukoApp: App {
    @State private var viewModel: LibraryViewModel

    init() {
        do {
            let db = try DatabaseClient()
            let manager = LibraryManager(dbClient: db)
            _viewModel = State(wrappedValue: LibraryViewModel(dbClient: db, libraryManager: manager))
        } catch {
            fatalError("Database initialization failed: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            LibraryView(viewModel: viewModel)
        }
    }
}
