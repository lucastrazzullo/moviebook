//
//  MovieWebService.swift
//  MoviebookCommons
//
//  Created by Luca Strazzullo on 09/06/2023.
//

import Foundation

public protocol MovieWebService {

    func fetchMovie(with identifier: Movie.ID) async throws -> Movie
    func fetchMovieCollection(with identifier: MovieCollection.ID) async throws -> MovieCollection
    func fetchWatchProviders(with movieIdentifier: Movie.ID) async throws -> WatchProviders
    func fetchPopular(page: Int?) async throws -> (results: [MovieDetails], nextPage: Int?)
    func fetchUpcoming(page: Int?) async throws -> (results: [MovieDetails], nextPage: Int?)
    func fetchTopRated(page: Int?) async throws -> (results: [MovieDetails], nextPage: Int?)
    func fetchNowPlaying(page: Int?) async throws -> (results: [MovieDetails], nextPage: Int?)

    init(requestManager: RequestManager)
}
