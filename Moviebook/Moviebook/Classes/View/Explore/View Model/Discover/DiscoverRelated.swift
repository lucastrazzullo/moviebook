//
//  DiscoverRelated.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 12/07/2023.
//

import Foundation
import MoviebookCommon

final class DiscoverRelated {

    struct ReferenceMovie {

        enum Weight {
            case exceptional
            case important
            case neutral
            case unwanted
        }

        let id: Movie.ID
        let weight: Weight

        init(id: Movie.ID, weight: Weight) {
            self.id = id
            self.weight = weight
        }

        init?(watchlistItem: WatchlistItem) {
            guard case .movie(let movieId) = watchlistItem.id else {
                return nil
            }

            if case .watched(let info) = watchlistItem.state, let rating = info.rating {
                self.weight = rating >= 9
                    ? .exceptional
                    : rating >= 7
                        ? .important
                        : rating < 6
                            ? .unwanted
                            : .neutral
            } else {
                self.weight = .neutral
            }

            self.id = movieId
        }
    }

    private var referenceMovies: [ReferenceMovie] = []
    private var keywordsFilter: [MovieKeyword.ID] = []
    private var genresFilter: [MovieGenre.ID] = []

    // MARK: Private methods

    func update(genresFilter: [MovieGenre.ID], referenceMovies: [ReferenceMovie], requestManager: RequestManager) async {
        self.referenceMovies = referenceMovies
        self.keywordsFilter = await withTaskGroup(of: [MovieKeyword.ID].self) { group in
            for watchlistMovie in referenceMovies {
                group.addTask {
                    await self.fetchItems(for: watchlistMovie, itemsProvider: {
                        try await WebService.movieWebService(requestManager: requestManager)
                            .fetchMovieKeywords(with: watchlistMovie.id)
                            .map(\.id)
                    })
                }
            }

            var keywords: [MovieKeyword.ID] = []
            for await response in group {
                keywords.append(contentsOf: response)
            }

            return keywords.getMostPopular(topCap: 3)
        }

        if genresFilter.isEmpty {
            self.genresFilter = await withTaskGroup(of: [MovieGenre.ID].self) { group in
                for watchlistMovie in referenceMovies {
                    group.addTask {
                        await self.fetchItems(for: watchlistMovie, itemsProvider: {
                            try await WebService.movieWebService(requestManager: requestManager)
                                .fetchMovie(with: watchlistMovie.id)
                                .genres.map(\.id)
                        })
                    }
                }

                var genres: [MovieGenre.ID] = []
                for await response in group {
                    genres.append(contentsOf: response)
                }

                return genres.getMostPopular(topCap: 3)
            }
        } else {
            self.genresFilter = genresFilter
        }
    }
}

extension DiscoverRelated: ExploreContentDataProvider {

    func fetch(requestManager: RequestManager, page: Int?) async throws -> ExploreContentDataProvider.Response {
        if genresFilter.isEmpty && keywordsFilter.isEmpty {
            return (results: .movies([]), nextPage: nil)
        }

        let movieIdsSet = Set(referenceMovies.map(\.id))
        var results: ExploreContentDataProvider.Response = (results: .movies([]), nextPage: page)
        repeat {
            let response = try await WebService
                .movieWebService(requestManager: requestManager)
                .fetchMovies(keywords: keywordsFilter,
                             genres: genresFilter,
                             page: results.nextPage)

            let filteredItems = response.results.filter { !movieIdsSet.contains($0.id) }
            let resultItems = results.results.appending(items: .movies(filteredItems))
            let resultNextPage = response.nextPage
            results = (results: resultItems, nextPage: resultNextPage)

        } while results.results.count < 10 && results.nextPage != nil

        return results
    }

    private func fetchItems<Item>(for watchlistMovie: ReferenceMovie, itemsProvider: () async throws -> [Item]) async -> [Item] {
        if case .unwanted = watchlistMovie.weight {
            return []
        }

        guard let items = try? await itemsProvider() else {
            return []
        }

        switch watchlistMovie.weight {
        case .exceptional:
            return (items+items+items+items)
        case .important:
            return (items+items)
        case .neutral:
            return items
        case .unwanted:
            return []
        }
    }
}
