import SwiftUI

struct EpisodeListView: View {
    @State private var viewModel: EpisodeListViewModel
    private let novel: Novel
    private let dbClient: DatabaseClient

    init(novel: Novel, dbClient: DatabaseClient, libraryManager: LibraryManager) {
        _viewModel = State(wrappedValue: EpisodeListViewModel(novel: novel, dbClient: dbClient, libraryManager: libraryManager))
        self.novel = novel
        self.dbClient = dbClient
    }

    var body: some View {
        List(viewModel.episodes, id: \.index) { episode in
            if let episodeId = episode.id, episode.content != nil {
                NavigationLink(destination: ReaderView(novel: novel, episodeId: episodeId, dbClient: dbClient)) {
                    EpisodeRow(episode: episode)
                }
            } else {
                EpisodeRow(episode: episode)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(novel.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if viewModel.isUpdating {
                    ProgressView()
                } else {
                    Button {
                        Task { await viewModel.update() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .overlay {
            if viewModel.isLoading && viewModel.episodes.isEmpty {
                ProgressView()
            } else if !viewModel.isLoading && viewModel.episodes.isEmpty {
                ContentUnavailableView(
                    "エピソードがありません",
                    systemImage: "doc.text",
                    description: Text("作品を登録し直してください")
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
        .task {
            await viewModel.load()
        }
    }
}

private struct EpisodeRow: View {
    let episode: Episode

    var body: some View {
        HStack {
            Text(episode.title)
                .font(.body)
            Spacer()
            if episode.content == nil {
                Image(systemName: "arrow.down.circle")
                    .foregroundStyle(.tertiary)
                    .font(.caption)
            }
        }
        .padding(.vertical, 2)
    }
}
