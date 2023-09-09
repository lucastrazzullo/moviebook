//
//  PopularArtistsViewModel.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 08/09/2023.
//

import Foundation
import MoviebookCommon

@MainActor final class PopularArtistsViewModel: ObservableObject {

    let content: ExploreContentViewModel

    init() {
        content = ExploreContentViewModel(
            dataProvider: DiscoverPopularArtists(),
            title: "Popular artists",
            subtitle: "based on your watchlist",
            items: .artists([])
        )
    }

    func start(watchlist: Watchlist, requestLoader: RequestLoader) {
        Task {
            await content.fetch(
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
}
