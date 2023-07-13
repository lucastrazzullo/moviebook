//
//  DiscoverSection.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 12/07/2023.
//

import Foundation
import MoviebookCommon

final class DiscoverSection: Identifiable {

    private let discoverSection: DiscoverMovieSection
    private var genresFilter: [MovieGenre.ID] = []
    private var watchedMoviesFilter: [Movie.ID] = []

    init(discoverSection: DiscoverMovieSection) {
        self.discoverSection = discoverSection
    }

    func update(genresFilter: [MovieGenre.ID], watchlistItems: [WatchlistItem]) async {
        self.genresFilter = genresFilter
        self.watchedMoviesFilter = watchlistItems
            .compactMap { item in
                if case .watched = item.state, case .movie(let id) = item.id {
                    return id
                } else {
                    return nil
                }
            }
    }
}

extension DiscoverSection: ExploreContentDataProvider {

    var id: String {
        return title
    }

    var title: String {
        switch discoverSection {
        case .nowPlaying:
            return NSLocalizedString("MOVIE.NOW_PLAYING", comment: "")
        case .upcoming:
            return NSLocalizedString("MOVIE.UPCOMING", comment: "")
        case .popular:
            return NSLocalizedString("MOVIE.POPULAR", comment: "")
        case .topRated:
            return NSLocalizedString("MOVIE.TOP_RATED", comment: "")
        }
    }

    var subtitle: String? {
        nil
    }

    func fetch(requestManager: RequestManager, page: Int?) async throws -> ExploreContentDataProvider.Response {
        var results: ExploreContentDataProvider.Response = (results: .movies([]), nextPage: page)
        repeat {
            let response = try await WebService
                .movieWebService(requestManager: requestManager)
                .fetchMovies(discoverSection: discoverSection, genres: genresFilter, page: results.nextPage)

            let movieIdsSet = Set(watchedMoviesFilter)
            let filteredItems = response.results.filter { !movieIdsSet.contains($0.id) }
            let resultItems = results.results.appending(items: .movies(filteredItems))
            let resultNextPage = response.nextPage
            results = (results: resultItems, nextPage: resultNextPage)

        } while results.results.count < 10 && results.nextPage != nil

        return results
    }
}
