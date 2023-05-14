//
//  ExploreListItem.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 20/04/2023.
//

import Foundation

enum ExploreListItems {
    case movies([MovieDetails])
    case artists([ArtistDetails])

    func appending(items: ExploreListItems) -> Self {
        switch (self, items) {
        case (let .movies(movies), let .movies(newMovies)):
            return .movies(movies + newMovies)
        case (let .artists(artists), let .artists(newArtists)):
            return .artists(artists + newArtists)
        default:
            return items
        }
    }
}
