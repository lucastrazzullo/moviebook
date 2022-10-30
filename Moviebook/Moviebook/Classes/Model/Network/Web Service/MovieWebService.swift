//
//  MovieWebService.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import Foundation

struct MovieWebService {

    struct URLFactory {

        static func makeMovieUrl(movieIdentifier: Movie.ID) throws -> URL {
            return try TheMovieDbDataRequestFactory.makeURL(path: "movie/\(movieIdentifier)")
        }
    }

    let requestManager: RequestManager

    func fetchMovie(with identifier: Movie.ID) async throws -> Movie {
        let url = try URLFactory.makeMovieUrl(movieIdentifier: identifier)
        let data = try await requestManager.request(from: url)
        let parsedResponse = try JSONDecoder().decode(Movie.self, from: data)
        return parsedResponse
    }
}
