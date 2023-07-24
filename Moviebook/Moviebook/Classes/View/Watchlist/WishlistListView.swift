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
import MoviebookTestSupport

struct WishlistListView_Previews: PreviewProvider {
    static let requestLoader = MockRequestLoader.shared
    static let watchlist = MockWatchlistProvider.shared.watchlist()
    static let viewModel = WatchlistViewModel()
    static var previews: some View {
        ScrollView {
            WishlistListView(
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
