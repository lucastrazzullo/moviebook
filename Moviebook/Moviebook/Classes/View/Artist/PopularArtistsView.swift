//
//  PopularArtistsView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 03/09/2023.
//

import SwiftUI
import MoviebookCommon

struct PopularArtistsView: View {

    @Environment(\.requestLoader) var requestLoader
    @EnvironmentObject var watchlist: Watchlist

    @StateObject var contentViewModel: ExploreContentViewModel

    @Binding var presentedItem: NavigationItem?

    var body: some View {
        ScrollView(showsIndicators: false) {
            ExploreVerticalSectionView(
                viewModel: contentViewModel,
                onItemSelected: { item in
                    presentedItem = item
                }
            )
        }
        .safeAreaInset(edge: .top) {
            VStack {
                Text(contentViewModel.title)
                    .font(.heroHeadline)
                if let subtitle = contentViewModel.subtitle {
                    Text(subtitle)
                        .font(.caption)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical)
            .background(.thinMaterial)
            .overlay(Rectangle().fill(.thinMaterial).frame(height: 1), alignment: .bottom)
        }
        .task {
            await contentViewModel.fetch(
                requestLoader: requestLoader,
                updateDataProvider: { dataProvider in
                    if let artists = dataProvider as? DiscoverPopularArtists {
                        await artists.update(
                            watchlistItems: watchlist.items,
                            requestLoader: requestLoader
                        )
                    }
                }
            )
        }
    }

    init(presentedItem: Binding<NavigationItem?>) {
        _presentedItem = presentedItem
        _contentViewModel = StateObject(
            wrappedValue: ExploreContentViewModel(
                dataProvider: DiscoverPopularArtists(),
                title: "Popular artists",
                subtitle: "based on your watchlist",
                items: .artists([])
            )
        )
    }
}

#if DEBUG

import MoviebookTestSupport

struct PopularArtistsView_Previews: PreviewProvider {
    static var previews: some View {
        PopularArtistsView(presentedItem: .constant(nil))
            .environmentObject(MockWatchlistProvider.shared.watchlist())
            .environment(\.requestLoader, MockRequestLoader.shared)
    }
}

#endif
