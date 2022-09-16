//
//  PopularWebService.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import Foundation

struct PopularWebService {

    let requestManager: RequestManager

    func fetch() async throws -> [MovieDetails] {
        let url = try TheMovieDbDataRequestFactory.makeURL(path: "movie/popular")
        let data = try await requestManager.request(from: url)
        let parsedResponse = try JSONDecoder().decode(TheMovieDbResponseWithResults<MovieDetails>.self, from: data)
        return parsedResponse.results
    }
}
