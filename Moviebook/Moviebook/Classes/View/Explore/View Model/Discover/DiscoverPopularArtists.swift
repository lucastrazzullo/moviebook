//
//  DiscoverPopularArtists.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 12/07/2023.
//

import Foundation
import MoviebookCommon

final class DiscoverPopularArtists: Identifiable {

    private var allArtists: [ArtistDetails] = []
    private let numberOfItemsPerPage: Int = 24

    func update(watchlistItems: [WatchlistItem], requestManager: RequestManager) async {
        let moviesInWatchlist = watchlistItems.compactMap { watchlistItem in
            switch watchlistItem.id {
            case .movie(id: let id):
                return id
            }
        }

        allArtists = await withTaskGroup(of: [ArtistDetails].self) { group in
            for movieIdentifier in moviesInWatchlist {
                group.addTask {
                    return (try? await WebService
                        .movieWebService(requestManager: requestManager)
                        .fetchMovieCast(with: movieIdentifier)) ?? []
                }
            }

            var results = [ArtistDetails]()
            for await response in group {
                results.append(contentsOf: response)
            }

            return results
        }
    }
}

extension DiscoverPopularArtists: ExploreContentDataProvider {

    var title: String {
        return "Popular artists"
    }

    var subtitle: String? {
        return allArtists.isEmpty ? nil : "Based on your watchlist"
    }

    func fetch(requestManager: RequestManager, page: Int?) async throws -> ExploreContentDataProvider.Response {
        let currentPage = page ?? 0

        let bottomCap = currentPage * numberOfItemsPerPage
        let topCap = bottomCap + numberOfItemsPerPage
        let artists = allArtists.getMostPopular(bottomCap: bottomCap, topCap: topCap)
        let nextPage = allArtists.count > topCap ? currentPage + 1 : nil

        return (results: .artists(artists), nextPage: nextPage)
    }
}
