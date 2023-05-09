//
//  UpcomingWebService.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import Foundation

struct UpcomingWebService {

    let requestManager: RequestManager

    func fetch() async throws -> [MovieDetails] {
        let url = try TheMovieDbDataRequestFactory.makeURL(path: "movie/upcoming")
        let data = try await requestManager.request(from: url)
        let parsedResponse = try JSONDecoder().decode(TheMovieDbResponseWithListResults<MovieDetails>.self, from: data)
        return parsedResponse.results
    }
}
