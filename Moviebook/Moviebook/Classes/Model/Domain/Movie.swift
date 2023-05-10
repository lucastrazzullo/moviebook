//
//  Movie.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import Foundation

struct Movie: Identifiable, Equatable {
    let id: Int
    let details: MovieDetails
    let genres: [MovieGenre]
    let cast: [ArtistDetails]
    let production: MovieProduction
    var watch: WatchProviderCollection
    var collection: MovieCollection?
}
