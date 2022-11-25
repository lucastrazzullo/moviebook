//
//  User.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import Foundation

final actor User {

    let watchlist: Watchlist

    init(watchlist: Watchlist) {
        self.watchlist = watchlist
    }
}
