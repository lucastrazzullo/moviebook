//
//  MovieGenre.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 30/10/2022.
//

import Foundation

public struct MovieGenre: Identifiable, Equatable, Hashable {
    public let id: Int
    public let name: String

    public init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
}
