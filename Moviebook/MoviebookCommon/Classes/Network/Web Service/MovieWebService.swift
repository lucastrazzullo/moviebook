//
//  MovieWebService.swift
//  MoviebookCommons
//
//  Created by Luca Strazzullo on 09/06/2023.
//

import Foundation

public enum DiscoverMovieSection: CaseIterable {
    case popular
    case upcoming
    case topRated
    case nowPlaying
}

public protocol MovieWebService {

    func fetchMovie(with identifier: Movie.ID) async throws -> Movie
    func fetchMovieCollection(with identifier: MovieCollection.ID) async throws -> MovieCollection
    func fetchMovieWatchProviders(with movieIdentifier: Movie.ID) async throws -> WatchProviders
    func fetchMovieKeywords(with movieIdentifier: Movie.ID) async throws -> [MovieKeyword]
    func fetchMovieCast(with movieIdentifier: Movie.ID) async throws -> [ArtistDetails]

    func fetchMovieGenres() async throws -> [MovieGenre]
    func fetchMovies(keywords: [MovieKeyword.ID], genres: [MovieGenre.ID], year: Int?, page: Int?) async throws -> (results: [MovieDetails], nextPage: Int?)
    func fetchMovies(discoverSection: DiscoverMovieSection, genres: [MovieGenre.ID], year: Int?, page: Int?) async throws -> (results: [MovieDetails], nextPage: Int?)
}
