//
//  MovieWebService.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import Foundation
import MoviebookCommon

public struct TheMovieDbMovieWebService: MovieWebService {

    private let requestManager: RequestManager

    public init(requestManager: RequestManager) {
        self.requestManager = requestManager
    }

    // MARK: - Movie

    public func fetchMovie(with identifier: Movie.ID) async throws -> Movie {
        let url = try TheMovieDbDataRequestFactory.makeURL(path: "movie/\(identifier)", queryItems: [
            URLQueryItem(name: "append_to_response", value: "credits,videos")
        ])
        let data = try await requestManager.request(from: url)
        var movie = try JSONDecoder().decode(TMDBMovieResponse.self, from: data).result

        if let collectionIdentifier = movie.collection?.id {
            movie.collection = try? await fetchCollection(with: collectionIdentifier)
        }

        if let watchProviders = try? await fetchWatchProviders(with: identifier) {
            movie.watch = watchProviders
        }

        return movie
    }

    private func fetchCollection(with identifier: MovieCollection.ID) async throws -> MovieCollection {
        let url = try TheMovieDbDataRequestFactory.makeURL(path: "collection/\(identifier)")
        let data = try await requestManager.request(from: url)
        return try JSONDecoder().decode(TMDBMovieCollectionResponse.self, from: data).result
    }

    private func fetchWatchProviders(with movieIdentifier: Movie.ID) async throws -> WatchProviders {
        let url = try TheMovieDbDataRequestFactory.makeURL(path: "movie/\(movieIdentifier)/watch/providers")
        let data = try await requestManager.request(from: url)
        let results = try JSONDecoder().decode(TMDBResponseWithDictionaryResults<TMDBWatchProviderCollectionResponse>.self, from: data).results.map { key, value in (key, value.result) }
        return WatchProviders(collections: Dictionary(uniqueKeysWithValues: results))
    }

    // MARK: - Movie lists

    public func fetchPopular(page: Int?) async throws -> (results: [MovieDetails], nextPage: Int?) {
        return try await fetchMovies(path: "movie/popular", page: page)
    }

    public func fetchUpcoming(page: Int?) async throws -> (results: [MovieDetails], nextPage: Int?) {
        return try await fetchMovies(path: "movie/upcoming", page: page)
    }

    public func fetchTopRated(page: Int?) async throws -> (results: [MovieDetails], nextPage: Int?) {
        return try await fetchMovies(path: "movie/top_rated", page: page)
    }

    public func fetchNowPlaying(page: Int?) async throws -> (results: [MovieDetails], nextPage: Int?) {
        return try await fetchMovies(path: "movie/now_playing", page: page)
    }

    private func fetchMovies(path: String, page: Int?) async throws -> (results: [MovieDetails], nextPage: Int?) {
        var queryItems = [URLQueryItem]()
        if let page {
            queryItems.append(URLQueryItem(name: "page", value: String(page)))
        }
        let url = try TheMovieDbDataRequestFactory.makeURL(path: path, queryItems: queryItems)
        let data = try await requestManager.request(from: url)
        let response = try JSONDecoder().decode(TMDBResponseWithListResults<TMDBMovieDetailsResponse>.self, from: data)

        return (results: response.results.map(\.result), nextPage: response.nextPage)
    }
}
