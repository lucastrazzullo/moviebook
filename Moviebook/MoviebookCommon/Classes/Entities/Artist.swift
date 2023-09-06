//
//  Artist.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 20/04/2023.
//

import Foundation

public struct Artist: Identifiable, Equatable, Hashable {
    public let id: Int
    public let details: ArtistDetails
    public let filmography: [MovieDetails]

    public var highlightedRelease: MovieDetails? {
        let currentDate = Date.now
        guard let minDate = Calendar.current.date(byAdding: .month, value: -1, to: currentDate) else {
            return nil
        }

        return filmography
            .sorted { $0.localisedReleaseDate() > $1.localisedReleaseDate() }
            .first { movieDetails in
                let releaseDate = movieDetails.localisedReleaseDate()
                return releaseDate > currentDate || releaseDate > minDate
            }
    }

    public init(id: Int, details: ArtistDetails, filmography: [MovieDetails]) {
        self.id = id
        self.details = details
        self.filmography = filmography.sorted { $0.release > $1.release }
    }
}
