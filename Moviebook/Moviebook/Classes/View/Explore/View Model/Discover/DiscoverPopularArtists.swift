//
//  DiscoverPopularArtists.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 12/07/2023.
//

import Foundation
import MoviebookCommon

final class DiscoverPopularArtists: Identifiable {

    private var moviesInWatchlist: [Movie.ID] = []

    func update(watchlistItems: [WatchlistItem], requestManager: RequestManager) async {
        moviesInWatchlist = watchlistItems.compactMap { watchlistItem in
            switch watchlistItem.id {
            case .movie(id: let id):
                return id
            }
        }
    }
}

extension DiscoverPopularArtists: ExploreContentDataProvider {

    var title: String {
        return "Popular artists"
    }

    var subtitle: String? {
        return moviesInWatchlist.isEmpty ? nil : "Based on your watchlist"
    }

    func fetch(requestManager: RequestManager, page: Int?) async throws -> ExploreContentDataProvider.Response {
        if moviesInWatchlist.isEmpty {
            let response = try await WebService
                .artistWebService(requestManager: requestManager)
                .fetchPopular(page: page)

            return (results: .artists(response.results), nextPage: response.nextPage)
        } else {
            var allArtists: [ArtistDetails] = []
            for movieIdentifier in moviesInWatchlist {
                let artists = try await WebService
                    .movieWebService(requestManager: requestManager)
                    .fetchMovieCast(with: movieIdentifier)

                allArtists.append(contentsOf: artists)
            }

            return (results: .artists(allArtists.getMostPopular(cap: 21)), nextPage: nil)
        }
    }
}
