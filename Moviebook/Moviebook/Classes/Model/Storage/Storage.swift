//
//  Storage.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 05/05/2023.
//

import Foundation
import Combine
import MoviebookCommon

actor Storage {

    private var subscriptions: Set<AnyCancellable> = []

    // MARK: Internal methods

    func loadWatchlist(requestLoader: RequestLoader) async throws -> Watchlist {
        let watchlistStorage = try await WatchlistStorage()
        let watchNextStorage = WatchNextStorage(webService: WebService.movieWebService(requestLoader: requestLoader))

        // Load items and watchlist
        let watchlistItems = try await watchlistStorage.fetchWatchlistItems()

        let watchlist = await Watchlist(items: watchlistItems)
        try await watchNextStorage.set(items: watchlistItems)

        await watchlist.itemsDidChange
            .removeDuplicates()
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { items in Task {
                try await watchlistStorage.store(items: items)
                try await watchNextStorage.set(items: items)
            }}
            .store(in: &subscriptions)

        return watchlist
    }
}
