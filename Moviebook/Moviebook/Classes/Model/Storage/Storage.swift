//
//  Storage.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 05/05/2023.
//

import Foundation
import Combine

actor Storage {

    private var subscriptions: Set<AnyCancellable> = []

    // MARK: Internal methods

    func loadWatchlist() async throws -> Watchlist {
        let watchlistStorage = try await WatchlistStorage()

        // Migrate from legacy storage
        let legacyWatchlistStorage = LegacyWatchlistStorage()
        if let legacyItems = try? await legacyWatchlistStorage.fetchWatchlistItems(), !legacyItems.isEmpty {
            try await watchlistStorage.store(items: legacyItems)
            try await legacyWatchlistStorage.deleteAllMovies()
        }

        // Load items and watchlist
        let watchlistItems = try await watchlistStorage.fetchWatchlistItems()
        let watchlist = await Watchlist(items: watchlistItems)

        // Listen for watchlist updates
        watchlist.itemsDidChange
            .removeDuplicates()
            .sink { items in Task { try await watchlistStorage.store(items: items) }}
            .store(in: &subscriptions)

        // Listen for remote updates
        await watchlistStorage.remoteUpdatesPublisher()
            .removeDuplicates()
            .sink { items in Task { await watchlist.set(items: items) }}
            .store(in: &subscriptions)

        return watchlist
    }
}
