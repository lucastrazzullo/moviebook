//
//  MovieCollection.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 16/09/2022.
//

import Foundation

struct MovieCollection: Identifiable {
    let id: Int
    let name: String
    let posterPath: String?
    let backdropPath: String?
}
