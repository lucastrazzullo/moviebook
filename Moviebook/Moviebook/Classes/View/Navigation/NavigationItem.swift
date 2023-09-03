//
//  NavigationItem.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 30/06/2023.
//

import Foundation
import MoviebookCommon

enum NavigationItem: Identifiable, Hashable {
    case explore(selectedGenres: Set<MovieGenre>)
    case movieWithIdentifier(_ id: Movie.ID)
    case popularArtists
    case artistWithIdentifier(_ id: Artist.ID)
    case watchlistAddToWatchReason(itemIdentifier: WatchlistItemIdentifier)
    case watchlistAddRating(itemIdentifier: WatchlistItemIdentifier)
    case unratedItems(_ items: [WatchlistViewItem])

    var id: AnyHashable {
        switch self {
        case .explore:
            return "Explore"
        case .movieWithIdentifier(let id):
            return id
        case .popularArtists:
            return "Popular artists"
        case .artistWithIdentifier(let id):
            return id
        case .watchlistAddToWatchReason(let item):
            return item.id
        case .watchlistAddRating(let item):
            return item.id
        case .unratedItems:
            return "Unrated items"
        }
    }
}
