//
//  MovieCollection.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 16/09/2022.
//

import Foundation

public struct MovieCollection: Identifiable, Equatable, Hashable {
    public let id: Int
    public let name: String
    public let list: [MovieDetails]?

    public init(id: Int, name: String, list: [MovieDetails]?) {
        self.id = id
        self.name = name
        self.list = list?.sorted { $0.release < $1.release }
    }
}
