//
//  PopularWebService.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import Foundation

struct PopularWebService {

    struct URLFactory {

        static func makePopularMoviesUrl() throws -> URL {
            return try TheMovieDbDataRequestFactory.makeURL(path: "movie/popular")
        }
    }

    let requestManager: RequestManager

    func fetch() async throws -> [MovieDetails] {
        let url = try URLFactory.makePopularMoviesUrl()
        let data = try await requestManager.request(from: url)
        let parsedResponse = try JSONDecoder().decode(TheMovieDbResponseWithResults<MovieDetails>.self, from: data)
        return parsedResponse.results
    }
}
