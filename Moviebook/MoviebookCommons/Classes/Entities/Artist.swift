//
//  Artist.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 20/04/2023.
//

import Foundation

public struct Artist: Identifiable {
    public let id: Int
    public let details: ArtistDetails
    public let filmography: [MovieDetails]

    public init(id: Int, details: ArtistDetails, filmography: [MovieDetails]) {
        self.id = id
        self.details = details
        self.filmography = filmography.sorted { $0.release > $1.release }
    }
}
