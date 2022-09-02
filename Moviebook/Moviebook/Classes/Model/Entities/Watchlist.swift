//
//  Watchlist.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import Foundation

final class Watchlist {

    var isEmpty: Bool {
        return toWatch.isEmpty && watched.isEmpty
    }

    private(set) var toWatch: [Movie.ID]
    private(set) var watched: [Movie.ID]

    init() {
        toWatch = []
        watched = []
    }
}

extension Watchlist: ObservableObject {}
