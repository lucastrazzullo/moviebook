//
//  NavigationItem.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 30/06/2023.
//

import Foundation
import MoviebookCommon

enum NavigationItem: Identifiable, Hashable {
    case explore
    case movieWithIdentifier(_ id: Movie.ID)
    case artistWithIdentifier(_ id: Artist.ID)
    case watchlistAddToWatchReason(itemIdentifier: WatchlistItemIdentifier)
    case watchlistAddRating(itemIdentifier: WatchlistItemIdentifier)

    var id: AnyHashable {
        switch self {
        case .explore:
            return "Explore"
        case .movieWithIdentifier(let id):
            return id
        case .artistWithIdentifier(let id):
            return id
        case .watchlistAddToWatchReason(let item):
            return item.id
        case .watchlistAddRating(let item):
            return item.id
        }
    }
}
