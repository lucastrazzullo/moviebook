//
//  DiscoverPopularArtists.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 12/07/2023.
//

import Foundation
import MoviebookCommon

final class DiscoverPopularArtists: Identifiable, ExploreContentDataProvider {

    var title: String {
        return "Popular artists"
    }

    let subtitle: String? = nil

    func fetch(requestManager: RequestManager, genres: [MovieGenre.ID], watchlistItems: [WatchlistItem], page: Int?) async throws -> ExploreContentDataProvider.Response {
        let response = try await WebService
            .artistWebService(requestManager: requestManager)
            .fetchPopular(page: page)

        return (results: .artists(response.results), nextPage: response.nextPage)
    }
}
