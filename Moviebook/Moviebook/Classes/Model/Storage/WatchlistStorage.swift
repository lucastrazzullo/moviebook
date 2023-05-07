//
//  WatchlistStorage.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 05/05/2023.
//

import Foundation
import CoreData
import Combine

actor WatchlistStorage {

    private let persistentContainer: NSPersistentContainer

    init() async throws {
        persistentContainer = NSPersistentCloudKitContainer(name: "Moviebook")
        try await load()
    }

    // MARK: - Internal methods

    func fetchWatchlistItems() async throws -> [WatchlistItem] {
        var result = [WatchlistItem]()

        let storedItemsToWatch = try await fetchStoredItemsToWatch()
        let itemsToWatch = try parse(storedItems: storedItemsToWatch)
        result.append(contentsOf: itemsToWatch)

        let storedWatchedItems = try await fetchStoredWatchedItems()
        let watchedItems = try parse(storedItems: storedWatchedItems)
        result.append(contentsOf: watchedItems)

        return result
    }

    func remoteUpdatesPublisher() -> AnyPublisher<[WatchlistItem], Never> {
        return NotificationCenter.default.publisher(
            for: NSNotification.Name.NSPersistentStoreRemoteChange,
            object: persistentContainer.persistentStoreCoordinator
        )
        .compactMap { $0.name == NSNotification.Name.NSPersistentStoreRemoteChange ? $0 : nil }
        .flatMap { _ in
            Future<[WatchlistItem], Error> { promise in
                Task {
                    do {
                        promise(.success(try await self.fetchWatchlistItems()))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }
        }
        .replaceError(with: [])
        .eraseToAnyPublisher()
    }

    func store(items: [WatchlistItem]) async throws {
        let storedItemsToWatch = try await fetchStoredItemsToWatch()
        let watchlistItemsToWatch = items.filter { if case .toWatch = $0.state { return true } else { return false }}
        try store(watchlistItems: watchlistItemsToWatch, storedItems: storedItemsToWatch, managedItemType: ManagedItemToWatch.self)

        let storedWatchedItems = try await fetchStoredWatchedItems()
        let watchlistWatchedItems = items.filter { if case .watched = $0.state { return true } else { return false }}
        try store(watchlistItems: watchlistWatchedItems, storedItems: storedWatchedItems, managedItemType: ManagedWatchedItem.self)

        save()
    }

    // MARK: - Private methods

    private func parse(storedItems: [any ManagedWatchlistItem]) throws -> [WatchlistItem] {
        var result = [WatchlistItem]()

        for storedItem in storedItems {
            guard let identifier = storedItem.watchlistItemIdentifier else { continue }
            guard let watchlistInfo = storedItem.watchlistInfo else { continue }

            if let itemToWatchInfo = watchlistInfo as? WatchlistItemToWatchInfo {
                result.append(WatchlistItem(id: identifier, state: .toWatch(info: itemToWatchInfo)))
            }

            if let watchedItemInfo = watchlistInfo as? WatchlistItemWatchedInfo {
                result.append(WatchlistItem(id: identifier, state: .watched(info: watchedItemInfo)))
            }
        }

        return result
    }

    private func load() async throws {
        try await withUnsafeThrowingContinuation { (continuation: UnsafeContinuation<Void, Error>) in
            if let description = persistentContainer.persistentStoreDescriptions.first {
                description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
                description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            }
            persistentContainer.loadPersistentStores(completionHandler: { description, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            })
        }
    }

    private func store(watchlistItems: [WatchlistItem],
                       storedItems: [any ManagedWatchlistItem],
                       managedItemType: any ManagedWatchlistItem.Type) throws {

        // Remove items that were deleted from watchlist
        for storedItem in storedItems {
            guard let identifier = storedItem.watchlistItemIdentifier, watchlistItems.contains(where: { $0.id == identifier }) else {
                delete(storedWatchlistItem: storedItem)
                continue
            }
        }

        // Add or modify existing items
        for itemToStore in watchlistItems {
            guard let storeableIdentifier = itemToStore.storeableIdentifier else { continue }

            let managedItemToStore = storedItems.first(where: { $0.identifier == storeableIdentifier }) ?? managedItemType.init(context: persistentContainer.viewContext)

            itemToStore.store(in: managedItemToStore, with: storeableIdentifier)
        }
    }

    // MARK: - Cloudkit methods

    private func fetchStoredItemsToWatch() async throws -> [ManagedItemToWatch] {
        let task = Task { @MainActor in
            let fetchRequest: NSFetchRequest<ManagedItemToWatch> = ManagedItemToWatch.fetchRequest()
            return try persistentContainer.viewContext.fetch(fetchRequest)
        }

        return try await task.value
    }

    private func fetchStoredWatchedItems() async throws -> [ManagedWatchedItem] {
        let task = Task { @MainActor in
            let fetchRequest: NSFetchRequest<ManagedWatchedItem> = ManagedWatchedItem.fetchRequest()
            return try persistentContainer.viewContext.fetch(fetchRequest)
        }

        return try await task.value
    }

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
}

private extension WatchlistItem {

    var storeableIdentifier: Data? {
        return try? JSONEncoder().encode(id)
    }

    func store(in managedWatchlistItem: any ManagedWatchlistItem, with identifier: Data) {
        managedWatchlistItem.identifier = identifier

        switch state {
        case .toWatch(let info):
            if let itemToWatch = managedWatchlistItem as? ManagedItemToWatch {
                itemToWatch.suggestionOwner = info.suggestion?.owner
                itemToWatch.suggestionComment = info.suggestion?.comment
            }
        case .watched(let info):
            if let watchedItem = managedWatchlistItem as? ManagedWatchedItem {
                watchedItem.date = info.date
                watchedItem.rating = info.rating ?? -1
                watchedItem.suggestionOwner = info.toWatchInfo.suggestion?.owner
                watchedItem.suggestionComment = info.toWatchInfo.suggestion?.comment
            }
        }
    }
}

// MARK: Managed Items

extension ManagedItemToWatch: ManagedWatchlistItem {

    var watchlistInfo: WatchlistItemToWatchInfo? {
        var toWatchSuggestion: WatchlistItemToWatchInfo.Suggestion? = nil
        if let owner = suggestionOwner, let comment = suggestionComment {
            toWatchSuggestion = WatchlistItemToWatchInfo.Suggestion(owner: owner, comment: comment)
        }

        return WatchlistItemToWatchInfo(suggestion: toWatchSuggestion)
    }
}

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