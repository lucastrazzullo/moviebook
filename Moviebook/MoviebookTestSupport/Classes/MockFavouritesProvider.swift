//
//  MockFavouritesProvider.swift
//  MoviebookTestSupport
//
//  Created by Luca Strazzullo on 08/09/2023.
//

import Foundation
import MoviebookCommon

@MainActor public final class MockFavouritesProvider {

    public init() {}

    public func favourites(empty: Bool = false) -> Favourites {
        if empty {
            return Favourites(items: [])
        } else {
            return Favourites(items: [
                FavouriteItem(id: .artist(id: 287), state: .pinned),
                FavouriteItem(id: .artist(id: 500), state: .pinned),
                FavouriteItem(id: .artist(id: 144080), state: .pinned)
            ])
        }
    }
}
