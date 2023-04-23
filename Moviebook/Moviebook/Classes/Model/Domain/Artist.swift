//
//  Artist.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 20/04/2023.
//

import Foundation

struct Artist: Identifiable {
    let id: Int
    let details: ArtistDetails
    let filmography: [MovieDetails]

    init(id: Int, details: ArtistDetails, filmography: [MovieDetails]) {
        self.id = id
        self.details = details
        self.filmography = filmography.sorted { $0.release > $1.release }
    }
}
