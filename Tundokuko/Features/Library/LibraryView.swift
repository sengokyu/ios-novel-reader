import SwiftUI

struct LibraryView: View {
    var viewModel: LibraryViewModel
    @AppStorage("appTheme") private var theme = "system"
    @Environment(\.scenePhase) private var scenePhase

    private var colorScheme: ColorScheme? {
        switch theme {
        case "light": .light
        case "dark": .dark
        default: nil
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(viewModel.novels, id: \.url) { novel in
                        let novelId = novel.id
                        NavigationLink(destination: EpisodeListView(novel: novel, dbClient: viewModel.dbClient, libraryManager: viewModel.libraryManager)) {
                            NovelRow(
                                novel: novel,
                                fetchedCount: novelId.flatMap { viewModel.fetchedCounts[$0] } ?? 0,
                                storageBytes: novelId.flatMap { viewModel.storageSizes[$0] } ?? 0
                            )
                        }
                    }
                    .onDelete { indexSet in
                        Task {
                            for i in indexSet {
                                await viewModel.delete(novel: viewModel.novels[i])
                            }
                        }
                    }
                }

                Section("ストレージ") {
                    HStack {
                        Text("合計使用量")
                        Spacer()
                        Text(viewModel.totalStorageBytes.formattedFileSize)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("積読庫")
            .overlay {
                if viewModel.isLoading && viewModel.novels.isEmpty {
                    ProgressView()
                } else if !viewModel.isLoading && viewModel.novels.isEmpty {
                    ContentUnavailableView(
                        "作品がありません",
                        systemImage: "books.vertical",
                        description: Text("Safari の共有メニューから小説を追加してください")
                    )
                }
            }
            .alert("エラー", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .toolbar {
                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gearshape")
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    Task { await viewModel.processPendingURL() }
                }
            }
            .refreshable {
                await viewModel.load()
            }
        }
        .preferredColorScheme(colorScheme)
    }
}

private struct NovelRow: View {
    let novel: Novel
    let fetchedCount: Int
    let storageBytes: Int64

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(novel.title)
                .font(.headline)
            Text(novel.author)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack {
                Text("\(fetchedCount) / \(novel.totalEpisodes) 話")
                Spacer()
                Text(storageBytes.formattedFileSize)
                Text(novel.updatedAt, style: .date)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

private extension Int64 {
    var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: self, countStyle: .file)
    }
}
