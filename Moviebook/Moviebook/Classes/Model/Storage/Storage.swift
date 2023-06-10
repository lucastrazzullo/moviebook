//
//  Storage.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 05/05/2023.
//

import Foundation
import Combine
import MoviebookCommons

actor Storage {

    private var subscriptions: Set<AnyCancellable> = []

    // MARK: Internal methods

    func loadWatchlist(requestManager: RequestManager) async throws -> Watchlist {
        let watchlistStorage = try await WatchlistStorage()
        let watchNextStorage = WatchNextStorage(webService: MovieWebService(requestManager: requestManager))

        // Migrate from legacy storage
        let legacyWatchlistStorage = LegacyWatchlistStorage()
        if let legacyItems = try? await legacyWatchlistStorage.fetchWatchlistItems(), !legacyItems.isEmpty {
            try await watchlistStorage.store(items: legacyItems)
            try await legacyWatchlistStorage.deleteAllMovies()
        }

        // Load items and watchlist
        let watchlistItems = try await watchlistStorage.fetchWatchlistItems()
        let watchlist = await Watchlist(items: watchlistItems)
        await watchNextStorage.set(items: watchlistItems)

        // Listen for watchlist updates
        await watchlist.itemsDidChange
            .removeDuplicates()
            .sink { items in Task {
                try await watchlistStorage.store(items: items)
                await watchNextStorage.set(items: items)
            }}
            .store(in: &subscriptions)

        // Listen for remote updates
        await watchlistStorage.remoteUpdatesPublisher()
            .removeDuplicates()
            .sink { items in Task {
                await watchlist.set(items: items)
                await watchNextStorage.set(items: items)
            }}
            .store(in: &subscriptions)

        return watchlist
    }
}
