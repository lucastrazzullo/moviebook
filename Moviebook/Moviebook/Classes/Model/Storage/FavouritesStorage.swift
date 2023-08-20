//
//  FavouritesStorage.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 20/08/2023.
//

import Foundation

import Foundation
import CoreData
import MoviebookCommon

actor FavouritesStorage {

    private let storage: CoreDataStorage

    init() async throws {
        self.storage = try await CoreDataStorage()
    }

    // MARK: - Internal methods

    func fetchFavourites() async throws -> [FavouriteItem] {
        return try await storage
            .fetch()
            .compactMap { (item: ManagedFavouriteItem) -> FavouriteItem? in
                guard let identifier = item.identifier,
                      let itemIdentifier = try? JSONDecoder().decode(FavouriteItemIdentifier.self, from: identifier) else {
                    return nil
                }

                guard let itemState = FavouriteItemState(rawValue: item.state) else {
                    return nil
                }

                return FavouriteItem(id: itemIdentifier, state: itemState)
            }
    }

    func store(items: [FavouriteItem]) async throws {
        try await storage.store(items: items, storedType: ManagedWatchedItem.self)
        await storage.save()
    }

    // MARK: Private helper methods

    private func map(storedItem: ManagedWatchlistItem) -> WatchlistItem? {
        guard let identifier = storedItem.identifier,
              let watchlistIdentifier = try? JSONDecoder().decode(WatchlistItemIdentifier.self, from: identifier),
              let state = storedItem.watchlistState else {
            return nil
        }

        return WatchlistItem(id: watchlistIdentifier, state: state)
    }
}

// MARK: - CoreData Storeable Item

extension FavouriteItem: CoreDataStoreableItem {

    var identifier: Data? {
        return try? JSONEncoder().encode(id)
    }

    func store(in managedWatchlistItem: NSManagedObject, with identifier: Data) {
        if let itemToWatch = managedWatchlistItem as? ManagedFavouriteItem {
            itemToWatch.identifier = identifier
        }
    }
}

// MARK: - CoreData Managed Item

extension ManagedFavouriteItem: CoreDataStoredItem {}
