//
//  MovieWebService.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import Foundation

struct MovieWebService {

    enum URLFactory {

        static func makeMovieUrl(movieIdentifier: Movie.ID) throws -> URL {
            return try TheMovieDbDataRequestFactory.makeURL(path: "movie/\(movieIdentifier)", queryItems: [
                URLQueryItem(name: "append_to_response", value: "credits,videos")
            ])
        }

        static func makeMovieCollectionUrl(collectionIdentifier: MovieCollection.ID) throws -> URL {
            return try TheMovieDbDataRequestFactory.makeURL(path: "collection/\(collectionIdentifier)")
        }
    }

    enum Parser {

        static func parseMovie(data: Data) throws -> Movie {
            return try JSONDecoder().decode(Movie.self, from: data)
        }

        static func parseCollection(data: Data) throws -> MovieCollection {
            return try JSONDecoder().decode(MovieCollection.self, from: data)
        }
    }

    let requestManager: RequestManager

    func fetchMovie(with identifier: Movie.ID) async throws -> Movie {
        let url = try URLFactory.makeMovieUrl(movieIdentifier: identifier)
        let data = try await requestManager.request(from: url)
        var movie = try Parser.parseMovie(data: data)

        if let collectionIdentifier = movie.collection?.id, let collection = try? await fetchCollection(with: collectionIdentifier) {
            movie.collection = collection
        }

        return movie
    }

    private func fetchCollection(with identifier: MovieCollection.ID) async throws -> MovieCollection {
        let url = try URLFactory.makeMovieCollectionUrl(collectionIdentifier: identifier)
        let data = try await requestManager.request(from: url)
        let parsedResponse = try Parser.parseCollection(data: data)
        return parsedResponse
    }
}
