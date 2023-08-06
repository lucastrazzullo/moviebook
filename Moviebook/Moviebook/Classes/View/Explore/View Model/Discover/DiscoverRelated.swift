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
    private var overriddenGenres: [MovieGenre.ID] = []

    // MARK: Private methods

    func update(referenceMovies: [ReferenceMovie], overrideGenres: [MovieGenre.ID], requestLoader: RequestLoader) async {
        self.referenceMovies = referenceMovies
        self.overriddenGenres = overrideGenres
    }
}

extension DiscoverRelated: ExploreContentDataProvider {

    func fetch(requestLoader: RequestLoader, page: Int?) async throws -> ExploreContentDataProvider.Response {
        let filters = await withTaskGroup(of: (movie: Movie, weight: ReferenceMovie.Weight)?.self) { group in
            for movieReference in referenceMovies {
                group.addTask {
                    if let movie = try? await WebService.movieWebService(requestLoader: requestLoader)
                        .fetchMovie(with: movieReference.id) {
                        return (movie: movie, weight: movieReference.weight)
                    } else {
                        return nil
                    }
                }
            }

            var keywords: [MovieKeyword.ID] = []
            var genres: [MovieGenre.ID] = []
            for await response in group {
                if let response {
                    let parsedKeywords = parseItems(response.movie.keywords.map(\.id), for: response.weight)
                    let parseGenres = parseItems(response.movie.genres.map(\.id), for: response.weight)
                    keywords.append(contentsOf: parsedKeywords)
                    genres.append(contentsOf: parseGenres)
                }
            }

            return (
                keywords: keywords.getMostPopular().cap(top: 3),
                genres: genres.getMostPopular().cap(top: 3)
            )
        }

        if filters.keywords.isEmpty && filters.genres.isEmpty {
            return (results: .movies([]), nextPage: nil)
        }

        let keywordsFilter = filters.keywords
        let genresFilter = overriddenGenres.isEmpty ? filters.genres : overriddenGenres

        let moviesAlreadyInReference = Set(referenceMovies.map(\.id))
        var results: ExploreContentDataProvider.Response = (results: .movies([]), nextPage: page)
        repeat {
            let response = try await WebService
                .movieWebService(requestLoader: requestLoader)
                .fetchMovies(keywords: keywordsFilter,
                             genres: genresFilter,
                             page: results.nextPage)

            let filteredItems = response.results.filter { !moviesAlreadyInReference.contains($0.id) }
            let resultItems = results.results.appending(items: .movies(filteredItems))
            let resultNextPage = response.nextPage
            results = (results: resultItems, nextPage: resultNextPage)

        } while results.results.count < 10 && results.nextPage != nil

        return results
    }

    private func parseItems<Item>(_ items: [Item], for weight: ReferenceMovie.Weight) -> [Item] {
        switch weight {
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
