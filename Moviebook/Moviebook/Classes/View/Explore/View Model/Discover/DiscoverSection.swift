//
//  DiscoverSection.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 12/07/2023.
//

import Foundation
import MoviebookCommon

final class DiscoverSection: Identifiable, ExploreContentDataProvider {

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

    let subtitle: String? = nil
    var genresFilter: [MovieGenre.ID]

    private let discoverSection: DiscoverMovieSection

    init(discoverSection: DiscoverMovieSection, discoverGenres: [MovieGenre.ID] = []) {
        self.discoverSection = discoverSection
        self.genresFilter = discoverGenres
    }

    // MARK: ExploreContentDataProvider

    func fetch(requestManager: RequestManager, page: Int?) async throws -> (results: ExploreContentItems, nextPage: Int?) {
        let response = try await WebService
            .movieWebService(requestManager: requestManager)
            .fetchMovies(discoverSection: discoverSection, genres: genresFilter, page: page)

        return (results: .movies(response.results), nextPage: response.nextPage)
    }
}
