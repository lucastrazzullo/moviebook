//
//  WishlistListView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 24/07/2023.
//

import SwiftUI

struct WishlistListView: View {

    let items: [WatchlistViewItem]
    let onItemSelected: (NavigationItem) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(spacing: 4), GridItem()], spacing: 4) {
            ForEach(items) { item in
                switch item {
                case .movie(let movie, _):
                    MovieShelfPreviewView(
                        movieDetails: movie.details,
                        onItemSelected: onItemSelected
                    )
                }
            }
        }
        .padding(.horizontal, 4)
    }
}

#if DEBUG
import MoviebookCommon
import MoviebookTestSupport

struct WishlistListView_Previews: PreviewProvider {
    static let requestLoader = MockRequestLoader.shared
    static let watchlist = MockWatchlistProvider.shared.watchlist(configuration: .toWatchItems(withSuggestion: true))
    static var previews: some View {
        ScrollView {
            WishlistListViewPreviewView()
        }
        .environment(\.requestLoader, requestLoader)
        .environmentObject(watchlist)
    }
}

@MainActor private final class ViewModel: ObservableObject {

    @Published var items: [WatchlistViewItem] = []

    func start(watchlist: Watchlist, requestLoader: RequestLoader) async {
        let content = WatchlistViewSectionContent(section: .toWatch)
        try? await content.updateItems(watchlist.items, requestLoader: requestLoader)
        items = content.items
    }
}

private struct WishlistListViewPreviewView: View {

    @Environment(\.requestLoader) var requestLoader
    @EnvironmentObject var watchlist: Watchlist

    @StateObject var viewModel = ViewModel()

    var body: some View {
        WishlistListView(
            items: viewModel.items,
            onItemSelected: { _ in }
        )
        .task {
            await viewModel.start(
                watchlist: watchlist,
                requestLoader: requestLoader
            )
        }
    }
}
#endif
