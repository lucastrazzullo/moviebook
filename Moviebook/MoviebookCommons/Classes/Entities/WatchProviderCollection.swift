//
//  WatchProviderCollection.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 08/05/2023.
//

import Foundation

public struct WatchProviderCollection: Equatable, Hashable {
    public let free: [WatchProvider]
    public let rent: [WatchProvider]
    public let buy: [WatchProvider]

    public var isEmpty: Bool {
        return free.isEmpty && rent.isEmpty && buy.isEmpty
    }

    public init(free: [WatchProvider], rent: [WatchProvider], buy: [WatchProvider]) {
        self.free = free
        self.rent = rent
        self.buy = buy
    }
}
