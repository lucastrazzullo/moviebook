//
//  WatchlistView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import SwiftUI

struct WatchlistView: View {

    @Environment(\.requestManager) var requestManager
    @EnvironmentObject var watchlist: Watchlist

    @StateObject private var viewModel: WatchlistViewModel = WatchlistViewModel()

    let onExploreSelected: () -> Void
    let onMovieSelected: (Movie) -> Void

    var body: some View {
        VStack(spacing: 0) {
            List {
                if viewModel.isLoading {
                    LoaderView()
                } else {
                    ForEach(viewModel.items) { item in
                        switch item {
                        case .movie(let movie, _, _):
                            MoviePreviewView(details: movie.details) {
                                onMovieSelected(movie)
                            }
                            .swipeActions {
                                Button(action: { viewModel.remove(item: item, from: watchlist) }) {
                                    HStack {
                                        Image(systemName: "minus")
                                        Text("Remove")
                                    }
                                }
                                .tint(Color.accentColor)
                            }
                        }
                    }
                    .listRowSeparator(.hidden)
                }
            }
            .scrollIndicators(.hidden)
            .listStyle(.plain)

            if let itemToRemove = viewModel.itemToRemove {
                switch itemToRemove {
                case .movie(let movie, let section, _):
                    HStack(spacing: 24) {
                        HStack {
                            AsyncImage(url: movie.details.media.posterPreviewUrl) { image in
                                image.resizable().aspectRatio(contentMode: .fit)
                            } placeholder: {
                                Color.gray
                            }
                            .frame(width: 60)
                            .cornerRadius(8)

                            VStack(alignment: .leading) {
                                Text("Removed from \(section.name)")
                                    .font(.subheadline)
                                    .foregroundColor(.accentColor)
                                Text(movie.details.title)
                                    .lineLimit(2)
                                    .font(.headline)
                            }
                        }

                        Spacer()

                        Button(action: { viewModel.undo() }) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Undo")
                                ProgressView(value: viewModel.undoTimeRemaining, total: 5)
                                    .progressViewStyle(.linear)
                                    .animation(.linear, value: viewModel.undoTimeRemaining)
                            }
                        }
                        .tint(Color.accentColor)
                        .fixedSize()
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding()
                    .background(Rectangle().fill(.background))
                }
            }
        }
        .navigationTitle(NSLocalizedString("WATCHLIST.TITLE", comment: ""))
        .toolbar {
            makeSectionSelectionToolbarItem()
            makeExploreToolbarItem()
        }
        .onAppear {
            viewModel.start(watchlist: watchlist, requestManager: requestManager)
        }
        .animation(.easeInOut(duration: 0.8), value: viewModel.itemToRemove)
    }

    // MARK: Private factory methods

    @ToolbarContentBuilder private func makeExploreToolbarItem() -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            WatermarkView {
                Image(systemName: "magnifyingglass")
                    .onTapGesture {
                        onExploreSelected()
                    }
            }
        }
    }

    @ToolbarContentBuilder private func makeSectionSelectionToolbarItem() -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Picker("Section", selection: $viewModel.currentSection) {
                ForEach(viewModel.sectionIdentifiers, id: \.self) { section in
                    Text(section.name)
                }
            }
            .segmentedStyled()
        }
    }
}

private struct EmptyWatchlistView: View {

    var onStartDiscoverySelected: () -> Void

    var body: some View {
        VStack {
            Text("Your watchlist is empty")
                .font(.headline)

            Button(action: onStartDiscoverySelected) {
                Label("Start your discovery", systemImage: "rectangle.and.text.magnifyingglass")
            }.buttonStyle(.borderedProminent)
        }
    }
}

#if DEBUG
struct WatchlistView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            WatchlistView(onExploreSelected: {}, onMovieSelected: { _ in })
                .environment(\.requestManager, MockRequestManager())
                .environmentObject(Watchlist(items: [
                    WatchlistItem(id: .movie(id: 954), state: .toWatch(info: .init(date: .now, suggestion: nil))),
                    WatchlistItem(id: .movie(id: 616037), state: .toWatch(info: .init(date: .now, suggestion: nil)))
                ]))
        }
    }
}
#endif
