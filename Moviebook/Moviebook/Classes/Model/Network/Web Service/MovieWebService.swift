//
//  MovieWebService.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import Foundation

struct MovieWebService {

    let requestManager: RequestManager

    func fetchDetails(with movieIdentifier: Movie.ID) async throws -> MovieDetails {
        let url = try TheMovieDbDataRequestFactory.makeURL(path: "movie/\(movieIdentifier)")
        let data = try await requestManager.request(from: url)
        let parsedResponse = try JSONDecoder().decode(MovieDetails.self, from: data)
        return parsedResponse
    }

    func fetchMovie(with identifier: Movie.ID) async throws -> Movie {
        let url = try TheMovieDbDataRequestFactory.makeURL(path: "movie/\(identifier)")
        let data = try await requestManager.request(from: url)
        let parsedResponse = try JSONDecoder().decode(Movie.self, from: data)
        return parsedResponse
    }
}
