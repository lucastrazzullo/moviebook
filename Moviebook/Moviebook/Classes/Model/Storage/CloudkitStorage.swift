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

    // MARK: - Internal methods

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

    // MARK: - Fetch

    func fetchWatchlistItems() throws -> [WatchlistItem] {
        var result = [WatchlistItem]()

        let storedItemsToWatch = try fetchStoredItemsToWatch()
        let itemsToWatch: [WatchlistItemIdentifier: WatchlistItemToWatchInfo] = try fetch(storedItems: storedItemsToWatch)
        for itemToWatchIdentifier in itemsToWatch.keys {
            if let info = itemsToWatch[itemToWatchIdentifier] {
                result.append(WatchlistItem(id: itemToWatchIdentifier, state: .toWatch(info: info)))
            }
        }

        let storedWatchedItems = try fetchStoredWatchedItems()
        let watchedItems: [WatchlistItemIdentifier: WatchlistItemWatchedInfo] = try fetch(storedItems: storedWatchedItems)
        for watchedItemIdentifier in watchedItems.keys {
            if let info = watchedItems[watchedItemIdentifier] {
                result.append(WatchlistItem(id: watchedItemIdentifier, state: .watched(info: info)))
            }
        }

        return result
    }

    private func fetchStoredItemsToWatch() throws -> [ManagedItemToWatch] {
        let fetchRequest: NSFetchRequest<ManagedItemToWatch> = ManagedItemToWatch.fetchRequest()
        return try persistentContainer.viewContext.fetch(fetchRequest)
    }

    private func fetchStoredWatchedItems() throws -> [ManagedWatchedItem] {
        let fetchRequest: NSFetchRequest<ManagedWatchedItem> = ManagedWatchedItem.fetchRequest()
        return try persistentContainer.viewContext.fetch(fetchRequest)
    }

    private func fetch<WatchlistInfo>(storedItems: [any ManagedWatchlistItem]) throws -> [WatchlistItemIdentifier: WatchlistInfo] {
        var result = [WatchlistItemIdentifier: WatchlistInfo]()

        for storedItem in storedItems {
            guard let identifier = storedItem.watchlistItemIdentifier else { continue }
            guard let watchlistInfo = storedItem.watchlistInfo else { continue }

            result[identifier] = watchlistInfo as? WatchlistInfo
        }

        return result
    }

    // MARK: - Store

    func store(items: [WatchlistItem]) throws {
        var itemsToWatch = [WatchlistItemIdentifier: WatchlistItemToWatchInfo]()
        var watchedItems = [WatchlistItemIdentifier: WatchlistItemWatchedInfo]()

        for item in items {
            switch item.state {
            case .toWatch(let info):
                itemsToWatch[item.id] = info
            case .watched(let info):
                watchedItems[item.id] = info
            }
        }

        try store(itemsToWatch: itemsToWatch)
        try store(watchedItems: watchedItems)
    }

    private func store(itemsToWatch: [WatchlistItemIdentifier: WatchlistItemToWatchInfo]) throws {
        let storedItems = try fetchStoredItemsToWatch()
        try store(watchlistItems: itemsToWatch, storedItems: storedItems, managedItemType: ManagedItemToWatch.self)
        save()
    }

    private func store(watchedItems: [WatchlistItemIdentifier: WatchlistItemWatchedInfo]) throws {
        let storedItems = try fetchStoredWatchedItems()
        try store(watchlistItems: watchedItems, storedItems: storedItems, managedItemType: ManagedWatchedItem.self)
        save()
    }

    private func store(watchlistItems: [WatchlistItemIdentifier: StoreableWatchlistItem],
                       storedItems: [any ManagedWatchlistItem],
                       managedItemType: any ManagedWatchlistItem.Type) throws {

        // Remove items that were deleted from watchlist
        for storedItem in storedItems {
            guard let identifier = storedItem.watchlistItemIdentifier, watchlistItems.keys.contains(identifier) else {
                delete(storedWatchlistItem: storedItem)
                continue
            }
        }

        // Add or modify existing items
        for itemIdentifier in watchlistItems.keys {
            guard let itemToStore = watchlistItems[itemIdentifier] else { continue }
            guard let storeableIdentifier = itemIdentifier.storeableIdentifier else { continue }

            let managedItemToStore = storedItems.first(where: { $0.hasIdentifier(watchlistItemIdentifier: itemIdentifier) }) ?? managedItemType.init(context: persistentContainer.viewContext)

            itemToStore.store(in: managedItemToStore, with: storeableIdentifier)
        }
    }

    // MARK: - Private helper methods

    private func delete(storedWatchlistItem: any ManagedWatchlistItem) {
        Task { @MainActor in
            persistentContainer.viewContext.delete(storedWatchlistItem)
        }
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

// MARK: - Private extensions

private protocol ManagedWatchlistItem: NSManagedObject {
    associatedtype WatchlistInfo

    var identifier: Data? { get set }

    var watchlistItemIdentifier: WatchlistItemIdentifier? { get }
    var watchlistInfo: WatchlistInfo? { get }
}

private extension ManagedWatchlistItem {

    var watchlistItemIdentifier: WatchlistItemIdentifier? {
        guard let identifier = identifier else { return nil }
        return try? JSONDecoder().decode(WatchlistItemIdentifier.self, from: identifier)
    }

    func hasIdentifier(watchlistItemIdentifier: WatchlistItemIdentifier) -> Bool {
        guard let storedItemIdentifier = self.watchlistItemIdentifier else { return false }
        return storedItemIdentifier == watchlistItemIdentifier
    }
}

private protocol StoreableWatchlistItem {

    func store(in storeableWatchlistItem: any ManagedWatchlistItem, with identifier: Data)
}

private extension WatchlistItemIdentifier {

    var storeableIdentifier: Data? {
        return try? JSONEncoder().encode(self)
    }
}

// MARK: To watch Item entities

extension ManagedItemToWatch: ManagedWatchlistItem {

    var watchlistInfo: WatchlistItemToWatchInfo? {
        var toWatchSuggestion: WatchlistItemToWatchInfo.Suggestion? = nil
        if let owner = suggestionOwner, let comment = suggestionComment {
            toWatchSuggestion = WatchlistItemToWatchInfo.Suggestion(owner: owner, comment: comment)
        }

        return WatchlistItemToWatchInfo(suggestion: toWatchSuggestion)
    }
}

extension WatchlistItemToWatchInfo: StoreableWatchlistItem {

    fileprivate func store(in storeableWatchlistItem: any ManagedWatchlistItem, with identifier: Data) {
        storeableWatchlistItem.identifier = identifier

        if let itemToWatch = storeableWatchlistItem as? ManagedItemToWatch {
            itemToWatch.suggestionOwner = suggestion?.owner
            itemToWatch.suggestionComment = suggestion?.comment
        }
    }
}

// MARK: Watched Item entities

extension ManagedWatchedItem: ManagedWatchlistItem {

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

extension WatchlistItemWatchedInfo: StoreableWatchlistItem {

    fileprivate func store(in storeableWatchlistItem: any ManagedWatchlistItem, with identifier: Data) {
        storeableWatchlistItem.identifier = identifier

        if let watchedItem = storeableWatchlistItem as? ManagedWatchedItem {
            watchedItem.date = date
            watchedItem.rating = rating ?? -1
            watchedItem.suggestionOwner = toWatchInfo.suggestion?.owner
            watchedItem.suggestionComment = toWatchInfo.suggestion?.comment
        }
    }
}
