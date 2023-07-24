//
//  WatchlistViewItem.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 24/07/2023.
//

import Foundation
import MoviebookCommon

enum WatchlistViewItem: Identifiable, Equatable {
    case movie(movie: Movie, watchlistItem: WatchlistItem)

    var id: WatchlistItemIdentifier {
        switch self {
        case .movie(_, let watchlistItem):
            return watchlistItem.id
        }
    }
}
