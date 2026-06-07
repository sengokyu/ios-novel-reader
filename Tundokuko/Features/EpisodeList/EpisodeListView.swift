import SwiftUI

private struct ReaderPresentation: Identifiable {
    let id: Int64
}

struct EpisodeListView: View {
    @State private var viewModel: EpisodeListViewModel
    @State private var readerPresentation: ReaderPresentation?
    private let novel: Novel
    private let dbClient: DatabaseClient
    private let libraryManager: LibraryManager

    init(novel: Novel, dbClient: DatabaseClient, libraryManager: LibraryManager) {
        _viewModel = State(wrappedValue: EpisodeListViewModel(novel: novel, dbClient: dbClient, libraryManager: libraryManager))
        self.novel = novel
        self.dbClient = dbClient
        self.libraryManager = libraryManager
    }

    var body: some View {
        List(viewModel.episodes, id: \.index) { episode in
            if let episodeId = episode.id {
                Button {
                    readerPresentation = ReaderPresentation(id: episodeId)
                } label: {
                    HStack {
                        EpisodeRow(episode: episode)
                        Spacer()
                        if viewModel.downloadingEpisodeIds.contains(episodeId) {
                            ProgressView()
                                .frame(width: 24, height: 24)
                        } else if episode.content == nil {
                            Button {
                                Task { await viewModel.downloadEpisode(episode) }
                            } label: {
                                Image(systemName: "arrow.down.circle")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
                .buttonStyle(.plain)
            } else {
                EpisodeRow(episode: episode)
                    .foregroundStyle(.secondary)
            }
        }
        .fullScreenCover(item: $readerPresentation, onDismiss: {
            Task { await viewModel.load() }
        }) { presentation in
            ReaderView(novel: novel, episodeId: presentation.id, dbClient: dbClient, libraryManager: libraryManager)
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
        Text(episode.title)
            .font(.body)
            .foregroundStyle(episode.content == nil ? .secondary : .primary)
            .padding(.vertical, 2)
    }
}
