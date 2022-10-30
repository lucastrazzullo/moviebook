//
//  SearchWebService.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 24/09/2022.
//

import Foundation

struct SearchWebService {

    let requestManager: RequestManager

    func fetchMovie(with keyword: String) async throws -> [MovieDetails] {
        let searchQueryItem = URLQueryItem(name: "query", value: keyword)
        let url = try TheMovieDbDataRequestFactory.makeURL(path: "search/movie", queryItems: [searchQueryItem])
        let data = try await requestManager.request(from: url)
        let parsedResponse = try JSONDecoder().decode(TheMovieDbResponseWithResults<MovieDetails>.self, from: data)
        return parsedResponse.results
    }
}
