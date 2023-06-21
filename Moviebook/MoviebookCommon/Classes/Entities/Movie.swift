//
//  Movie.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import Foundation

public struct Movie: Identifiable, Equatable, Hashable {
    public let id: Int
    public let details: MovieDetails
    public let genres: [MovieGenre]
    public let cast: [ArtistDetails]
    public let production: MovieProduction
    public var watch: WatchProviders
    public var collection: MovieCollection?

    public init(id: Int, details: MovieDetails, genres: [MovieGenre], cast: [ArtistDetails], production: MovieProduction, watch: WatchProviders, collection: MovieCollection? = nil) {
        self.id = id
        self.details = details
        self.genres = genres
        self.cast = cast
        self.production = production
        self.watch = watch
        self.collection = collection
    }
}
