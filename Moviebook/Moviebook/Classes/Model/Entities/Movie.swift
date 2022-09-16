//
//  Movie.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import Foundation

struct Movie: Identifiable {
    let id: Int
}

struct MovieDetails: Identifiable {
    let id: Movie.ID
    let title: String
    let collection: MovieCollection?
}

struct MovieCollection: Identifiable {
    let id: Int
    let name: String
}
