//
//  DiscoverCollections.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 11/09/2023.
//

import Foundation
import MoviebookCommon

final class DiscoverCollections {

    private var moviesToWatch: [MovieDetails] = []

    func update(watchlistItems: [WatchlistItem], requestLoader: RequestLoader) async {
        let collectionsInWatchlist = await withTaskGroup(of: MovieCollection?.self) { group in
            var result = [MovieCollection]()

            watchlistItems.forEach { item in
                group.addTask {
                    switch item.id {
                    case .movie(let id):
                        let webService = WebService.movieWebService(requestLoader: requestLoader)
                        let movie = try? await webService.fetchMovie(with: id)
                        return movie?.collection
                    }
                }
            }

            for await response in group {
                if let response, !result.contains(where: { $0.id == response.id }) {
                    result.append(response)
                }
            }

            return result
        }

        moviesToWatch = collectionsInWatchlist
            .compactMap { collection in return collection.list }
            .flatMap { list in return list }
            .filter { movie in
                var dateFromComponent = DateComponents()
                dateFromComponent.month = -5

                guard let dateFrom = Calendar.current.date(byAdding: dateFromComponent, to: .now) else {
                    return false
                }

                return (dateFrom...).contains(movie.localisedReleaseDate())
            }
            .filter { movie in
                return !watchlistItems.contains(where: { $0.id == .movie(id: movie.id) })
            }
    }
}

extension DiscoverCollections: ExploreContentDataProvider {

    func fetch(requestLoader: RequestLoader, page: Int?) async throws -> ExploreContentDataProvider.Response {
        return (results: .movies(moviesToWatch), nextPage: nil)
    }
}
