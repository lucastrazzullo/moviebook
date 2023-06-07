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
    @State private var presentedItemNavigationPath = NavigationPath()
    @State private var presentedItem: NavigationItem? = nil

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    LoaderView()
                } else if viewModel.items.isEmpty {
                    EmptyWatchlistView(
                        section: $viewModel.currentSection,
                        onStartDiscoverySelected: { presentedItem = .explore }
                    )
                } else {
                    ListView(
                        viewModel: viewModel,
                        onMovieSelected: { movie in presentedItem = .movie(movie) },
                        onAddToWatchReason: { watchlistItemIdentifier in
                            presentedItem = .watchlistAddToWatchReason(itemIdentifier: watchlistItemIdentifier)
                        },
                        onAddRating: { watchlistItemIdentifier in
                            presentedItem = .watchlistAddRating(itemIdentifier: watchlistItemIdentifier)
                        }
                    )
                }
            }
            .watchlistPrompt(duration: 5)
            .navigationTitle(NSLocalizedString("WATCHLIST.TITLE", comment: ""))
            .toolbar {
                makeSectionSelectionToolbarItem()
                makeExploreToolbarItem()
            }
            .sheet(item: $presentedItem) { item in
                Navigation(path: $presentedItemNavigationPath, presentingItem: item)
            }
            .onAppear {
                viewModel.start(watchlist: watchlist, requestManager: requestManager)
            }
        }
    }

    // MARK: Private factory methods

    @ToolbarContentBuilder private func makeExploreToolbarItem() -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            WatermarkView {
                Image(systemName: "magnifyingglass")
                    .onTapGesture {
                        presentedItem = .explore
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

private struct ListView: View {

    @EnvironmentObject var watchlist: Watchlist

    @ObservedObject var viewModel: WatchlistViewModel

    let onMovieSelected: (Movie) -> Void
    let onAddToWatchReason: (WatchlistItemIdentifier) -> Void
    let onAddRating: (WatchlistItemIdentifier) -> Void

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(), GridItem()]) {
                ForEach(viewModel.items) { item in
                    switch item {
                    case .movie(let movie, _, let watchlistIdentifier):
                        Group {
                            AsyncImage(url: movie.details.media.posterPreviewUrl, content: { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            }, placeholder: {
                                Color
                                    .gray
                                    .opacity(0.2)
                            })
                            .aspectRatio(contentMode: .fill)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .onTapGesture {
                            onMovieSelected(movie)
                        }
                        .contextMenu {
                            WatchlistOptions(
                                watchlistItemIdentifier: watchlistIdentifier,
                                onAddToWatchReason: {
                                    onAddToWatchReason(watchlistIdentifier)
                                },
                                onAddRating: {
                                    onAddRating(watchlistIdentifier)
                                }
                            )
                        }
                    }
                }
            }
            .padding(4)
        }
        .scrollIndicators(.hidden)
    }
}

#if DEBUG
struct WatchlistView_Previews: PreviewProvider {
    static var previews: some View {
        WatchlistView()
            .environment(\.requestManager, MockRequestManager())
            .environmentObject(Watchlist(items: [
                WatchlistItem(id: .movie(id: 954), state: .toWatch(info: .init(date: .now, suggestion: nil))),
                WatchlistItem(id: .movie(id: 353081), state: .toWatch(info: .init(date: .now, suggestion: nil))),
                WatchlistItem(id: .movie(id: 575265), state: .toWatch(info: .init(date: .now, suggestion: nil))),
                WatchlistItem(id: .movie(id: 616037), state: .watched(info: .init(toWatchInfo: .init(date: .now, suggestion: nil), date: .now)))
            ]))

        WatchlistView()
            .environment(\.requestManager, MockRequestManager())
            .environmentObject(Watchlist(items: [
                WatchlistItem(id: .movie(id: 954), state: .toWatch(info: .init(date: .now, suggestion: nil))),
                WatchlistItem(id: .movie(id: 616037), state: .toWatch(info: .init(date: .now, suggestion: nil)))
            ]))

        WatchlistView()
            .environment(\.requestManager, MockRequestManager())
            .environmentObject(Watchlist(items: []))
    }
}
#endif
