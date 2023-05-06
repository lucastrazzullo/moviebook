//
//  Storage.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 05/05/2023.
//

import Foundation
import Combine

actor Storage {

    private let watchlist: Watchlist
    private let underlyingStorage: CloudkitStorage

    private var subscriptions: Set<AnyCancellable> = []

    init(watchlist: Watchlist) {
        self.watchlist = watchlist
        self.underlyingStorage = CloudkitStorage()
    }

    func load() async throws {
        try await underlyingStorage.load()
        try await populateWatchlist()

        await watchlist.$toWatchItems
            .sink(receiveValue: { items in Task { try await self.underlyingStorage.store(itemsToWatch: items) }})
            .store(in: &subscriptions)
        await watchlist.$watchedItems
            .sink(receiveValue: { items in Task { try await self.underlyingStorage.store(items: items) }})
            .store(in: &subscriptions)
    }

    private func populateWatchlist() async throws {
        let itemsToWatch = try await underlyingStorage.getItemsToWatch()
        for identifier in itemsToWatch.keys {
            await MainActor.run {
                if let info = itemsToWatch[identifier] {
                    watchlist.update(state: .toWatch(info: info), forItemWith: identifier)
                }
            }
        }

        let watchedItems = try await underlyingStorage.getWatchedItems()
        for identifier in watchedItems.keys {
            await MainActor.run {
                if let info = watchedItems[identifier] {
                    watchlist.update(state: .watched(info: info), forItemWith: identifier)
                }
            }
        }
    }
}
