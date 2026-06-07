import SwiftUI

struct ReaderView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showsOverlay = false
    @State private var viewModel: ReaderViewModel
    private let episodeId: Int64

    init(novel: Novel, episodeId: Int64, dbClient: DatabaseClient, libraryManager: LibraryManager) {
        _viewModel = State(wrappedValue: ReaderViewModel(novel: novel, dbClient: dbClient, libraryManager: libraryManager))
        self.episodeId = episodeId
    }

    var body: some View {
        ZStack {
            ReaderWebView(controller: viewModel.controller)
                .ignoresSafeArea()

            GeometryReader { geo in
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        let x = location.x
                        let w = geo.size.width
                        if x < w * 0.25 {
                            viewModel.controller.pageForward()
                        } else if x > w * 0.75 {
                            viewModel.controller.pageBack()
                        } else {
                            withAnimation(.easeInOut(duration: 0.2)) { showsOverlay.toggle() }
                            return
                        }
                        withAnimation(.easeInOut(duration: 0.2)) { showsOverlay = false }
                    }
            }
            .ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView()
            }
        }
        .overlay(alignment: .top) {
            if showsOverlay {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title3)
                    }
                    .frame(width: 44, height: 44)

                    Spacer()

                    Text(viewModel.episode?.title ?? "")
                        .font(.subheadline)
                        .lineLimit(1)
                        .padding(.horizontal)

                    Spacer()

                    Color.clear.frame(width: 44, height: 44)
                }
                .background(.regularMaterial)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .task {
            await viewModel.load(episodeId: episodeId)
        }
        .onDisappear {
            Task { await viewModel.savePosition() }
        }
    }
}
