//
//  WatchProviderCollection.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 08/05/2023.
//

import Foundation

struct WatchProviderCollection: Equatable {
    let free: [WatchProvider]
    let rent: [WatchProvider]
    let buy: [WatchProvider]

    var isEmpty: Bool {
        return free.isEmpty && rent.isEmpty && buy.isEmpty
    }

    init(free: [WatchProvider], rent: [WatchProvider], buy: [WatchProvider]) {
        self.free = free
        self.rent = rent
        self.buy = buy
    }
}
