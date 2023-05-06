//
//  CloudkitStorage.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 05/05/2023.
//

import Foundation
import CoreData

actor CloudkitStorage {

    private let persistentContainer: NSPersistentContainer

    init() {
        persistentContainer = NSPersistentContainer(name: "Moviebook")
    }

    func load() async throws {
        try await withUnsafeThrowingContinuation { (continuation: UnsafeContinuation<Void, Error>) in
            persistentContainer.loadPersistentStores(completionHandler: { description, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            })
        }
    }

    // MARK: - To watch

    func getItemsToWatch() throws -> [WatchlistItemIdentifier: WatchlistItemToWatchInfo] {
        var result = [WatchlistItemIdentifier: WatchlistItemToWatchInfo]()
        let storedItemsToWatch = try getStoredItemsToWatch()

        for storedItemToWatch in storedItemsToWatch {
            guard let identifier = storedItemToWatch.watchlistItemIdentifier else { continue }

            result[identifier] = storedItemToWatch.watchlistInfo
        }
        return result
    }

    func store(itemsToWatch: [WatchlistItemIdentifier: WatchlistItemToWatchInfo]) throws {
        let storedItemsToWatch = try getStoredItemsToWatch()

        for storedItemToWatch in storedItemsToWatch {
            guard let identifier = storedItemToWatch.watchlistItemIdentifier, !itemsToWatch.keys.contains(identifier) else {
                delete(storedWatchlistItem: storedItemToWatch)
                continue
            }
        }

        for itemIdentifier in itemsToWatch.keys {
            guard let itemToStore = itemsToWatch[itemIdentifier] else { continue }
            guard let storeableIdentifier = itemIdentifier.storeableIdentifier else { continue }

            let managedItemToStore =
                storedItemsToWatch.first(where: { $0.hasIdentifier(watchlistItemIdentifier: itemIdentifier) }) ??
                ItemToWatch(context: persistentContainer.viewContext)

            itemToStore.store(in: managedItemToStore, with: storeableIdentifier)
        }

        save()
    }

    private func getStoredItemsToWatch() throws -> [ItemToWatch] {
        let fetchRequest: NSFetchRequest<ItemToWatch> = ItemToWatch.fetchRequest()
        return try persistentContainer.viewContext.fetch(fetchRequest)
    }

    // MARK: - Watched

    func getWatchedItems() throws -> [WatchlistItemIdentifier: WatchlistItemWatchedInfo] {
        var result = [WatchlistItemIdentifier: WatchlistItemWatchedInfo]()
        let storedItems = try getStoredWatchedItems()

        for storedItem in storedItems {
            guard let identifier = storedItem.watchlistItemIdentifier else { continue }
            guard let watchlistInfo = storedItem.watchlistInfo else { continue }

            result[identifier] = watchlistInfo
        }

        return result
    }

    func store(items: [WatchlistItemIdentifier: WatchlistItemWatchedInfo]) throws {
        let storedItems = try getStoredWatchedItems()

        for storedItem in storedItems {
            guard let identifier = storedItem.watchlistItemIdentifier, !items.keys.contains(identifier) else {
                delete(storedWatchlistItem: storedItem)
                continue
            }
        }

        for itemIdentifier in items.keys {
            guard let itemToStore = items[itemIdentifier] else { continue }
            guard let storeableIdentifier = itemIdentifier.storeableIdentifier else { continue }

            let managedItemToStore =
                storedItems.first(where: { $0.hasIdentifier(watchlistItemIdentifier: itemIdentifier) }) ??
                WatchedItem(context: persistentContainer.viewContext)

            itemToStore.store(in: managedItemToStore, with: storeableIdentifier)
        }

        save()
    }

    private func getStoredWatchedItems() throws -> [WatchedItem] {
        let fetchRequest: NSFetchRequest<WatchedItem> = WatchedItem.fetchRequest()
        return try persistentContainer.viewContext.fetch(fetchRequest)
    }

    // MARK: - Private helper methods

    private func delete(storedWatchlistItem: StoreableWatchlistItem) {
        persistentContainer.viewContext.delete(storedWatchlistItem)
    }

    private func save() {
        Task { @MainActor in
            do {
                try persistentContainer.viewContext.save()
            } catch {
                persistentContainer.viewContext.rollback()
                print("Failed to save context: \(error)")
            }
        }
    }
}

// MARK: Private extensions

private protocol StoreableWatchlistItem: NSManagedObject {
    var identifier: Data? { get }
}

extension StoreableWatchlistItem {

    var watchlistItemIdentifier: WatchlistItemIdentifier? {
        guard let identifier = identifier else { return nil }
        return try? JSONDecoder().decode(WatchlistItemIdentifier.self, from: identifier)
    }

    func hasIdentifier(watchlistItemIdentifier: WatchlistItemIdentifier) -> Bool {
        guard let storedItemIdentifier = self.watchlistItemIdentifier else { return false }
        return storedItemIdentifier == watchlistItemIdentifier
    }
}

// MARK: Common watchlist entities

private extension WatchlistItemIdentifier {

    var storeableIdentifier: Data? {
        return try? JSONEncoder().encode(self)
    }
}

// MARK: To watch Item entities

extension ItemToWatch: StoreableWatchlistItem {

    var watchlistInfo: WatchlistItemToWatchInfo {
        var toWatchSuggestion: WatchlistItemToWatchInfo.Suggestion? = nil
        if let owner = suggestionOwner, let comment = suggestionComment {
            toWatchSuggestion = WatchlistItemToWatchInfo.Suggestion(owner: owner, comment: comment)
        }

        return WatchlistItemToWatchInfo(suggestion: toWatchSuggestion)
    }
}

private extension WatchlistItemToWatchInfo {

    func store(in storeableWatchlistItem: ItemToWatch, with identifier: Data) {
        storeableWatchlistItem.identifier = identifier
        storeableWatchlistItem.suggestionOwner = suggestion?.owner
        storeableWatchlistItem.suggestionComment = suggestion?.comment
    }
}

// MARK: Watched Item entities

extension WatchedItem: StoreableWatchlistItem {

    var watchlistInfo: WatchlistItemWatchedInfo? {
        guard let date = date else { return nil }

        var toWatchSuggestion: WatchlistItemToWatchInfo.Suggestion? = nil
        if let owner = suggestionOwner, let comment = suggestionComment {
            toWatchSuggestion = WatchlistItemToWatchInfo.Suggestion(owner: owner, comment: comment)
        }

        let toWatchInfo = WatchlistItemToWatchInfo(suggestion: toWatchSuggestion)
        let rating = rating > -1 ? rating : nil

        return WatchlistItemWatchedInfo(toWatchInfo: toWatchInfo, rating: rating, date: date)
    }
}

private extension WatchlistItemWatchedInfo {

    func store(in storeableWatchlistItem: WatchedItem, with identifier: Data) {
        storeableWatchlistItem.identifier = identifier
        storeableWatchlistItem.date = date
        storeableWatchlistItem.rating = rating ?? -1
        storeableWatchlistItem.suggestionOwner = toWatchInfo.suggestion?.owner
        storeableWatchlistItem.suggestionComment = toWatchInfo.suggestion?.comment
    }
}
