//
//  User.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import Foundation

final class User {

    static let shared: User = User(watchlist: Watchlist())

    let watchlist: Watchlist

    private init(watchlist: Watchlist) {
        self.watchlist = watchlist
    }
}
