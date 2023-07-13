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

    // MARK: Requests

    public func fetchMovie(with identifier: Movie.ID) async throws -> Movie {
        let url = try TheMovieDbUrlFactory.movie(identifier: identifier).makeUrl()
        let data = try await requestManager.request(from: url)
        var movie = try JSONDecoder().decode(TMDBMovieResponse.self, from: data).result

        if let collectionIdentifier = movie.collection?.id {
            movie.collection = try? await fetchMovieCollection(with: collectionIdentifier)
        }

        if let watchProviders = try? await fetchMovieWatchProviders(with: identifier) {
            movie.watch = watchProviders
        }

        return movie
    }

    public func fetchMovieCollection(with identifier: MovieCollection.ID) async throws -> MovieCollection {
        let url = try TheMovieDbUrlFactory.movieCollection(identifier: identifier).makeUrl()
        let data = try await requestManager.request(from: url)
        return try JSONDecoder().decode(TMDBMovieCollectionResponse.self, from: data).result
    }

    public func fetchMovieWatchProviders(with movieIdentifier: Movie.ID) async throws -> WatchProviders {
        let url = try TheMovieDbUrlFactory.movieWatchProviders(movieIdentifier: movieIdentifier).makeUrl()
        let data = try await requestManager.request(from: url)
        let results = try JSONDecoder().decode(TMDBResponseWithDictionaryResults<TMDBWatchProviderCollectionResponse>.self, from: data).results.map { key, value in (key, value.result) }
        return WatchProviders(collections: Dictionary(uniqueKeysWithValues: results))
    }

    public func fetchMovieKeywords(with movieIdentifier: Movie.ID) async throws -> [MovieKeyword] {
        let url = try TheMovieDbUrlFactory.movieKeywords(movieIdentifier: movieIdentifier).makeUrl()
        let data = try await requestManager.request(from: url)
        return try JSONDecoder().decode(TMDBMovieKeywordsResponse.self, from: data).keywords.map(\.result)
    }

    public func fetchMovieCast(with movieIdentifier: Movie.ID) async throws -> [ArtistDetails] {
        let url = try TheMovieDbUrlFactory.movieCredits(movieIdentifier: movieIdentifier).makeUrl()
        let data = try await requestManager.request(from: url)
        return try JSONDecoder().decode(TMDBMovieCastResponse.self, from: data).result
    }

    public func fetchMovieGenres() async throws -> [MovieGenre] {
        let url = try TheMovieDbUrlFactory.movieGenres.makeUrl()
        let data = try await requestManager.request(from: url)
        return try JSONDecoder().decode(TMDBMovieGenresResponse.self, from: data).genres.map(\.result)
    }

    public func fetchMovies(keywords: [MovieKeyword.ID], genres: [MovieGenre.ID], page: Int?) async throws -> (results: [MovieDetails], nextPage: Int?) {
        let url = try TheMovieDbUrlFactory.movies(keywords: keywords, genres: genres, page: page).makeUrl()
        let data = try await requestManager.request(from: url)
        let response = try JSONDecoder().decode(TMDBResponseWithListResults<TMDBMovieDetailsResponse>.self, from: data)

        return (results: response.results.map(\.result), nextPage: response.nextPage)
    }

    public func fetchMovies(discoverSection: DiscoverMovieSection, genres: [MovieGenre.ID], page: Int?) async throws -> (results: [MovieDetails], nextPage: Int?) {
        let url = try TheMovieDbUrlFactory.discover(section: discoverSection, genres: genres, page: page).makeUrl()
        let data = try await requestManager.request(from: url)
        let response = try JSONDecoder().decode(TMDBResponseWithListResults<TMDBMovieDetailsResponse>.self, from: data)

        return (results: response.results.map(\.result), nextPage: response.nextPage)
    }
}
