//
//  TheMovieDbSearchWebService.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 24/09/2022.
//

import Foundation
import MoviebookCommon

public struct TheMovieDbSearchWebService: SearchWebService {

    private let requestLoader: RequestLoader

    public init(requestLoader: RequestLoader) {
        self.requestLoader = requestLoader
    }

    public func fetchMovies(with keyword: String, page: Int? = nil) async throws -> (results: [MovieDetails], nextPage: Int?) {
        let url = try TheMovieDbUrlFactory.searchMovie(keyword: keyword, page: page).makeUrl()
        let data = try await requestLoader.request(from: url)
        let response = try JSONDecoder().decode(TMDBResponseWithListResults<TMDBMovieDetailsResponse>.self, from: data)
        return (results: response.results.map(\.movieDetails), nextPage: response.nextPage)
    }

    public func fetchArtists(with keyword: String, page: Int? = nil) async throws -> (results: [ArtistDetails], nextPage: Int?) {
        let url = try TheMovieDbUrlFactory.searchPerson(keyword: keyword, page: page).makeUrl()
        let data = try await requestLoader.request(from: url)
        let response = try JSONDecoder().decode(TMDBResponseWithListResults<TMDBArtistDetailsResponse>.self, from: data)
        return (results: response.results.map(\.artistDetails), nextPage: response.nextPage)
    }
}
