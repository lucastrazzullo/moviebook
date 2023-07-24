//
//  WatchedListView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 24/07/2023.
//

import SwiftUI

struct WatchedListView: View {

    let items: [WatchlistViewItem]
    let onItemSelected: (NavigationItem) -> Void

    var body: some View {
        LazyVStack {
            ForEach(items) { item in
                switch item {
                case .movie(let movie, _):
                    MoviePreviewView(
                        details: movie.details,
                        onItemSelected: onItemSelected
                    )
                }
            }
        }
        .padding(.horizontal)
    }
}

#if DEBUG
import MoviebookTestSupport

struct WatchedListView_Previews: PreviewProvider {
    static let requestLoader = MockRequestLoader.shared
    static let watchlist = MockWatchlistProvider.shared.watchlist(configuration: .watchedItems(withSuggestion: true, withRating: true))
    static let viewModel = WatchlistViewModel()
    static var previews: some View {
        ScrollView {
            WatchedListView(
                items: viewModel.items,
                onItemSelected: { _ in }
            )
        }
        .task {
            viewModel.section = .watched
            await viewModel.start(
                watchlist: watchlist,
                requestLoader: requestLoader
            )
        }
        .environment(\.requestLoader, requestLoader)
        .environmentObject(watchlist)
    }
}
#endif
