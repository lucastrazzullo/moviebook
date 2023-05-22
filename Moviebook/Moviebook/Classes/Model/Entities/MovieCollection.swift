//
//  MovieCollection.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 16/09/2022.
//

import Foundation

struct MovieCollection: Identifiable, Equatable, Hashable {
    let id: Int
    let name: String
    let list: [MovieDetails]?

    init(id: Int, name: String, list: [MovieDetails]?) {
        self.id = id
        self.name = name
        self.list = list?.sorted { $0.release < $1.release }
    }
}
