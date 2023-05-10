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
        return try JSONDecoder().decode(TMDBResponseWithListResults<TMDBMovieDetailsResponse>.self, from: data).results.map(\.result)
    }

    func fetchArtists(with keyword: String) async throws -> [ArtistDetails] {
        let searchQueryItem = URLQueryItem(name: "query", value: keyword)
        let url = try TheMovieDbDataRequestFactory.makeURL(path: "search/person", queryItems: [searchQueryItem])
        let data = try await requestManager.request(from: url)
        return try JSONDecoder().decode(TMDBResponseWithListResults<TMDBArtistDetailsResponse>.self, from: data).results.map(\.result)
    }
}
