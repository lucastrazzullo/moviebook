//
//  WatchlistViewItem.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 24/07/2023.
//

import Foundation
import MoviebookCommon

enum WatchlistViewItem: Identifiable, Equatable, Hashable {
    case movie(movie: Movie, watchlistItem: WatchlistItem)

    var id: AnyHashable {
        watchlistItem.id
    }

    var addedDate: Date {
        watchlistItem.date
    }

    var name: String {
        switch self {
        case .movie(let movie, _):
            return movie.details.title
        }
    }

    var releaseDate: Date {
        switch self {
        case .movie(let movie, _):
            return movie.details.localisedReleaseDate()
        }
    }

    var rating: Float {
        switch self {
        case .movie(let movie, let watchlistItem):
            switch watchlistItem.state {
            case .toWatch:
                return movie.details.rating.value
            case .watched(let info):
                return Float(info.rating ?? 0)
            }
        }
    }

    var watchlistItem: WatchlistItem {
        switch self {
        case .movie(_, let watchlistItem):
            return watchlistItem
        }
    }
}
