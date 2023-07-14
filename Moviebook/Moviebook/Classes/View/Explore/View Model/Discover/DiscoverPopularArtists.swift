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

    enum ContentPage: Int {
        case capped = 0
        case expanded = 1

        var cap: Int? {
            switch self {
            case .capped:
                return 24
            case .expanded:
                return nil
            }
        }

        init?(rawValue: Int) {
            switch rawValue {
            case 0:
                self = .capped
            case 1:
                self = .expanded
            default:
                return nil
            }
        }
    }

    var title: String {
        return "Popular artists"
    }

    var subtitle: String? {
        return moviesInWatchlist.isEmpty ? nil : "Based on your watchlist"
    }

    func fetch(requestManager: RequestManager, page: Int?) async throws -> ExploreContentDataProvider.Response {
        if moviesInWatchlist.isEmpty {
            return (results: .movies([]), nextPage: nil)
        }

        let currentPage: ContentPage
        if let page {
            currentPage = ContentPage(rawValue: page) ?? .capped
        } else {
            currentPage = .capped
        }

        var allArtists: [ArtistDetails] = []
        for movieIdentifier in moviesInWatchlist {
            let artists = try await WebService
                .movieWebService(requestManager: requestManager)
                .fetchMovieCast(with: movieIdentifier)

            allArtists.append(contentsOf: artists)
        }

        let nextPage: ContentPage?
        switch currentPage {
        case .capped:
            nextPage = .expanded
        case .expanded:
            nextPage = nil
        }

        return (results: .artists(allArtists.getMostPopular(cap: currentPage.cap)), nextPage: nextPage?.rawValue)
    }
}
