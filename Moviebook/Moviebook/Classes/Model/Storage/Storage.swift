//
//  Storage.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 05/05/2023.
//

import Foundation
import CoreData
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

        await populateWatchlist()
        await watchlist.$toWatchItems
            .sink(receiveValue: { items in Task { await self.underlyingStorage.store(items: items) }})
            .store(in: &subscriptions)
        await watchlist.$watchedItems
            .sink(receiveValue: { items in Task { await self.underlyingStorage.store(items: items) }})
            .store(in: &subscriptions)
    }

    private func populateWatchlist() async {
        let itemsToWatch = await underlyingStorage.getItemsToWatch()
        let watchedItems = await underlyingStorage.getWatchedItems()

        for item in itemsToWatch {
            var toWatchSuggestion: WatchlistItemToWatchInfo.Suggestion? = nil
            if let owner = item.suggestionOwner, let comment = item.suggestionComment {
                toWatchSuggestion = WatchlistItemToWatchInfo.Suggestion(owner: owner, comment: comment)
            }
            let toWatchInfo = WatchlistItemToWatchInfo(suggestion: toWatchSuggestion)

            if let identifierData = item.identifier, let identifier = try? JSONDecoder().decode(WatchlistItemIdentifier.self, from: identifierData) {
                await MainActor.run {
                    watchlist.update(state: .toWatch(info: toWatchInfo), forItemWith: identifier)
                }
            }
        }

        for item in watchedItems {
            var toWatchSuggestion: WatchlistItemToWatchInfo.Suggestion? = nil
            if let owner = item.suggestionOwner, let comment = item.suggestionComment {
                toWatchSuggestion = WatchlistItemToWatchInfo.Suggestion(owner: owner, comment: comment)
            }
            let toWatchInfo = WatchlistItemToWatchInfo(suggestion: toWatchSuggestion)

            let rating = item.rating > -1 ? item.rating : nil
            guard let date = item.date else { continue }
            let watchedInfo = WatchlistItemWatchedInfo(toWatchInfo: toWatchInfo, rating: rating, date: date)

            if let identifierData = item.identifier, let identifier = try? JSONDecoder().decode(WatchlistItemIdentifier.self, from: identifierData) {
                await MainActor.run {
                    watchlist.update(state: .watched(info: watchedInfo), forItemWith: identifier)
                }
            }
        }
    }
}

// MARK: Cloudkit storage

protocol StoredItem {
    var identifier: Data? { get }
}

extension ItemToWatch: StoredItem {}
extension WatchedItem: StoredItem {}

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

    func getItemsToWatch() -> [ItemToWatch] {
        let fetchRequest: NSFetchRequest<ItemToWatch> = ItemToWatch.fetchRequest()

        do {
            return try persistentContainer.viewContext.fetch(fetchRequest)
        } catch {
            print("Failed to fetch movies: \(error)")
            return []
        }
    }

    func store(items: [WatchlistItemIdentifier: WatchlistItemToWatchInfo]) {
        let storedItemsToWatch = getItemsToWatch()

        for storedItemToWatch in storedItemsToWatch {
            guard let identifierData = storedItemToWatch.identifier else {
                persistentContainer.viewContext.delete(storedItemToWatch)
                continue
            }
            guard let identifier = try? JSONDecoder().decode(WatchlistItemIdentifier.self, from: identifierData) else {
                persistentContainer.viewContext.delete(storedItemToWatch)
                continue
            }

            if !items.keys.contains(identifier) {
                persistentContainer.viewContext.delete(storedItemToWatch)
            }
        }

        for itemIdentifier in items.keys {
            guard let itemToStore = items[itemIdentifier] else { continue }
            guard let identifierData = try? JSONEncoder().encode(itemIdentifier) else { continue }

            let managedItemToStore =
                storedItemsToWatch.first(where: identifier(is: itemIdentifier)) ??
                ItemToWatch(context: persistentContainer.viewContext)

            managedItemToStore.identifier = identifierData
            managedItemToStore.suggestionOwner = itemToStore.suggestion?.owner
            managedItemToStore.suggestionComment = itemToStore.suggestion?.comment
        }

        save()
    }

    // MARK: - Watched

    func getWatchedItems() -> [WatchedItem] {
        let fetchRequest: NSFetchRequest<WatchedItem> = WatchedItem.fetchRequest()

        do {
            return try persistentContainer.viewContext.fetch(fetchRequest)
        } catch {
            print("Failed to fetch movies: \(error)")
            return []
        }
    }

    func store(items: [WatchlistItemIdentifier: WatchlistItemWatchedInfo]) {
        let storedWatchedItems = getWatchedItems()

        for storedWatchedItem in storedWatchedItems {
            guard let identifierData = storedWatchedItem.identifier else {
                persistentContainer.viewContext.delete(storedWatchedItem)
                continue
            }
            guard let identifier = try? JSONDecoder().decode(WatchlistItemIdentifier.self, from: identifierData) else {
                persistentContainer.viewContext.delete(storedWatchedItem)
                continue
            }

            if !items.keys.contains(identifier) {
                persistentContainer.viewContext.delete(storedWatchedItem)
            }
        }

        for itemIdentifier in items.keys {
            guard let itemToStore = items[itemIdentifier] else { continue }
            guard let identifierData = try? JSONEncoder().encode(itemIdentifier) else { continue }

            let managedItemToStore =
                storedWatchedItems.first(where: identifier(is: itemIdentifier)) ??
                WatchedItem(context: persistentContainer.viewContext)

            managedItemToStore.identifier = identifierData
            managedItemToStore.date = itemToStore.date
            managedItemToStore.rating = itemToStore.rating ?? -1
            managedItemToStore.suggestionOwner = itemToStore.toWatchInfo.suggestion?.owner
            managedItemToStore.suggestionComment = itemToStore.toWatchInfo.suggestion?.comment
        }

        save()
    }

    // MARK: - Private helper methods

    private func identifier<ResultType: StoredItem>(is watchlistItemIdentifier: WatchlistItemIdentifier) -> (ResultType) -> Bool {
        return { (item: ResultType) in
            guard let identifier = item.identifier else { return false }
            guard let storedItemIdentifier = try? JSONDecoder().decode(WatchlistItemIdentifier.self, from: identifier) else { return false }
            return storedItemIdentifier == watchlistItemIdentifier
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
