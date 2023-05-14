//
//  UpcomingWebService.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import Foundation

struct UpcomingWebService {

    let requestManager: RequestManager

    func fetch(page: Int?) async throws -> (results: [MovieDetails], nextPage: Int?) {
        var queryItems = [URLQueryItem]()
        if let page {
            queryItems.append(URLQueryItem(name: "page", value: String(page)))
        }
        let url = try TheMovieDbDataRequestFactory.makeURL(path: "movie/upcoming", queryItems: queryItems)
        let data = try await requestManager.request(from: url)
        let response = try JSONDecoder().decode(TMDBResponseWithListResults<TMDBMovieDetailsResponse>.self, from: data)

        return (results: response.results.map(\.result), nextPage: response.nextPage)
    }
}
