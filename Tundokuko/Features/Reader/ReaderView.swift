import SwiftUI

struct ReaderView: View {
    @State private var viewModel: ReaderViewModel
    private let episodeId: Int64

    init(novel: Novel, episodeId: Int64, dbClient: DatabaseClient) {
        _viewModel = State(wrappedValue: ReaderViewModel(novel: novel, dbClient: dbClient))
        self.episodeId = episodeId
    }

    var body: some View {
        ZStack {
            ReaderWebView(controller: viewModel.controller)
                .ignoresSafeArea()

            // Left tap zone: page forward (later in story)
            // Right tap zone: page back (earlier in story)
            // This matches Japanese book reading direction (right→left)
            HStack(spacing: 0) {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { viewModel.controller.pageForward() }
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { viewModel.controller.pageBack() }
            }
            .ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView()
            }
        }
        .navigationTitle(viewModel.episode?.title ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load(episodeId: episodeId)
        }
        .onDisappear {
            Task { await viewModel.savePosition() }
        }
    }
}
