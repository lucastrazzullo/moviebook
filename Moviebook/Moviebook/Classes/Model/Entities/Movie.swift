//
//  Movie.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import Foundation

struct Movie: Identifiable {
    let id: Int
    let details: MovieDetails
    let collection: MovieCollection?
}
