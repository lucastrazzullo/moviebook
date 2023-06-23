//
//  TheMovieDbSearchWebService.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 24/09/2022.
//

import Foundation
import MoviebookCommon

public struct TheMovieDbSearchWebService: SearchWebService {

    private let requestManager: RequestManager

    public init(requestManager: RequestManager) {
        self.requestManager = requestManager
    }

    public func fetchMovies(with keyword: String, page: Int? = nil) async throws -> (results: [MovieDetails], nextPage: Int?) {
        var queryItems = [URLQueryItem(name: "query", value: keyword)]
        if let page {
            queryItems.append(URLQueryItem(name: "page", value: String(page)))
        }
        let url = try TheMovieDbDataRequestFactory.makeURL(path: "search/movie", queryItems: queryItems)
        let data = try await requestManager.request(from: url)
        let response = try JSONDecoder().decode(TMDBResponseWithListResults<TMDBMovieDetailsResponse>.self, from: data)
        return (results: response.results.map(\.result), nextPage: response.nextPage)
    }

    public func fetchArtists(with keyword: String, page: Int? = nil) async throws -> (results: [ArtistDetails], nextPage: Int?) {
        var queryItems = [URLQueryItem(name: "query", value: keyword)]
        if let page {
            queryItems.append(URLQueryItem(name: "page", value: String(page)))
        }
        let url = try TheMovieDbDataRequestFactory.makeURL(path: "search/person", queryItems: queryItems)
        let data = try await requestManager.request(from: url)
        let response = try JSONDecoder().decode(TMDBResponseWithListResults<TMDBArtistDetailsResponse>.self, from: data)
        return (results: response.results.map(\.result), nextPage: response.nextPage)
    }
}
