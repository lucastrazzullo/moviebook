//
//  MovieWebService.swift
//  MoviebookCommons
//
//  Created by Luca Strazzullo on 09/06/2023.
//

import Foundation

public enum DiscoverMovieSection {
    case popular
    case upcoming
    case topRated
    case nowPlaying
}

public protocol MovieWebService {

    func fetchMovie(with identifier: Movie.ID) async throws -> Movie
    func fetchMovieCollection(with identifier: MovieCollection.ID) async throws -> MovieCollection
    func fetchWatchProviders(with movieIdentifier: Movie.ID) async throws -> WatchProviders

    func fetchMovieGenres() async throws -> [MovieGenre]
    func fetch(discoverSection: DiscoverMovieSection, genre: MovieGenre.ID?, page: Int?) async throws -> (results: [MovieDetails], nextPage: Int?)
}
