//
//  MovieDetailsWebService.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import Foundation

struct MovieDetailsWebService {

    let requestManager: RequestManager

    func fetch(with movieIdentifier: Movie.ID) async throws -> MovieDetails {
        let url = try TheMovieDbRequestFactory.makeURL(path: "movie/\(movieIdentifier)")
        let data = try await requestManager.request(from: url)
        let parsedResponse = try JSONDecoder().decode(MovieDetails.self, from: data)
        return parsedResponse
    }
}
