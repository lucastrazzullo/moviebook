//
//  SearchWebService.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 24/09/2022.
//

import Foundation

struct SearchWebService {

    let requestManager: RequestManager

    func fetchMovies(with keyword: String) async throws -> [MovieDetails] {
        let searchQueryItem = URLQueryItem(name: "query", value: keyword)
        let url = try TheMovieDbDataRequestFactory.makeURL(path: "search/movie", queryItems: [searchQueryItem])
        let data = try await requestManager.request(from: url)
        let parsedResponse = try JSONDecoder().decode(TheMovieDbResponseWithListResults<MovieDetails>.self, from: data)
        return parsedResponse.results
    }

    func fetchArtists(with keyword: String) async throws -> [ArtistDetails] {
        let searchQueryItem = URLQueryItem(name: "query", value: keyword)
        let url = try TheMovieDbDataRequestFactory.makeURL(path: "search/person", queryItems: [searchQueryItem])
        let data = try await requestManager.request(from: url)
        let parsedResponse = try JSONDecoder().decode(TheMovieDbResponseWithListResults<ArtistDetails>.self, from: data)
        return parsedResponse.results
    }
}
