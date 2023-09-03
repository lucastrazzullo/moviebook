//
//  WatchlistViewPinnedItem.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 21/08/2023.
//

import Foundation
import MoviebookCommon

enum WatchlistViewPinnedItem: Hashable {
    case artist(ArtistDetails, FavouriteItemIdentifier)

    // MARK: View properties

    var favouritesIdentifier: FavouriteItemIdentifier {
        switch self {
        case .artist(_, let favouritesIdentifier):
            return favouritesIdentifier
        }
    }
}
