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
        return try JSONDecoder().decode(TMDBResponseWithListResults<TMDBMovieDetailsResponse>.self, from: data).results.map(\.result)
    }
}
