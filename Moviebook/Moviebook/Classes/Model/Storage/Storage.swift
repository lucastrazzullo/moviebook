//
//  Storage.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 05/05/2023.
//

import Foundation
import Combine

actor Storage {

    private let underlyingStorage: CloudkitStorage
    private var subscriptions: Set<AnyCancellable> = []

    init() {
        self.underlyingStorage = CloudkitStorage()
    }

    // MARK: Internal methods

    func loadWatchlist() async throws -> Watchlist {
        try await underlyingStorage.load()

        let watchlistItems = try await underlyingStorage.fetchWatchlistItems()
        let watchlist = await Watchlist(items: watchlistItems)

        watchlist.objectDidChange
            .removeDuplicates()
            .sink { items in Task { try await self.underlyingStorage.store(items: items) }}
            .store(in: &subscriptions)

        await underlyingStorage.updatesPublisher()
            .removeDuplicates()
            .sink { items in Task { await watchlist.set(items: items) }}
            .store(in: &subscriptions)

        return watchlist
    }
}
