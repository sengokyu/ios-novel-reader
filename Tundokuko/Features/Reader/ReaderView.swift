import SwiftUI

struct ReaderView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showsOverlay = false
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

            Color.clear
                .contentShape(Rectangle())
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) { showsOverlay.toggle() }
                }
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
