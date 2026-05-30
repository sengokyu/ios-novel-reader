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

            // Japanese book direction: left=forward (later), right=back (earlier)
            HStack(spacing: 0) {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { viewModel.controller.pageForward() }
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { viewModel.controller.pageBack() }
            }
            .ignoresSafeArea()
            .gesture(
                DragGesture(minimumDistance: 40)
                    .onEnded { value in
                        if value.translation.width < 0 {
                            viewModel.controller.pageForward()
                        } else {
                            viewModel.controller.pageBack()
                        }
                    }
            )

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
