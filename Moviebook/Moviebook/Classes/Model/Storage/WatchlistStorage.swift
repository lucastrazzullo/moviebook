//
//  WatchlistStorage.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 05/05/2023.
//

import Foundation
import CoreData
import MoviebookCommon

actor WatchlistStorage {

    private let storage: CoreDataStorage

    init() async throws {
        self.storage = try await CoreDataStorage()
    }

    // MARK: - Internal methods

    func fetchWatchlistItems() async throws -> [WatchlistItem] {
        var result = [WatchlistItem]()

        let itemsToWatch = try await storage
            .fetch()
            .compactMap { (item: ManagedItemToWatch) -> WatchlistItem? in return map(storedItem: item) }
        let watchedItems = try await storage
            .fetch()
            .compactMap { (item: ManagedWatchedItem) -> WatchlistItem? in return map(storedItem: item) }

        result.append(contentsOf: itemsToWatch)
        result.append(contentsOf: watchedItems)

        return result
    }

    func store(items: [WatchlistItem]) async throws {
        let watchlistItemsToWatch = items.filter { if case .toWatch = $0.state { return true } else { return false }}
        let watchlistWatchedItems = items.filter { if case .watched = $0.state { return true } else { return false }}

        try await storage.store(items: watchlistItemsToWatch, storedType: ManagedItemToWatch.self)
        try await storage.store(items: watchlistWatchedItems, storedType: ManagedWatchedItem.self)

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

extension WatchlistItem: CoreDataStoreableItem {

    var identifier: Data? {
        return try? JSONEncoder().encode(id)
    }

    func store(in managedWatchlistItem: NSManagedObject, with identifier: Data) {
        switch state {
        case .toWatch(let info):
            if let itemToWatch = managedWatchlistItem as? ManagedItemToWatch {
                itemToWatch.identifier = identifier
                itemToWatch.date = info.date
                itemToWatch.suggestionOwner = info.suggestion?.owner
                itemToWatch.suggestionComment = info.suggestion?.comment
            }
        case .watched(let info):
            if let watchedItem = managedWatchlistItem as? ManagedWatchedItem {
                watchedItem.identifier = identifier
                watchedItem.date = info.date
                watchedItem.rating = info.rating ?? -1
                watchedItem.suggestionOwner = info.toWatchInfo.suggestion?.owner
                watchedItem.suggestionComment = info.toWatchInfo.suggestion?.comment
            }
        }
    }
}

// MARK: - CoreData Managed Items

protocol ManagedWatchlistItem {
    var identifier: Data? { get }
    var watchlistState: WatchlistItemState? { get }
}

extension ManagedItemToWatch: CoreDataStoredItem {}
extension ManagedItemToWatch: ManagedWatchlistItem {

    var watchlistState: WatchlistItemState? {
        guard let date = date else { return nil }

        var toWatchSuggestion: WatchlistItemToWatchInfo.Suggestion? = nil
        if suggestionOwner != nil || suggestionComment != nil {
            toWatchSuggestion = WatchlistItemToWatchInfo.Suggestion(owner: suggestionOwner, comment: suggestionComment)
        }

        return .toWatch(info: WatchlistItemToWatchInfo(date: date, suggestion: toWatchSuggestion))
    }
}

extension ManagedWatchedItem: CoreDataStoredItem {}
extension ManagedWatchedItem: ManagedWatchlistItem {

    var watchlistState: WatchlistItemState? {
        guard let date = date else { return nil }

        var toWatchSuggestion: WatchlistItemToWatchInfo.Suggestion? = nil
        if let owner = suggestionOwner {
            toWatchSuggestion = WatchlistItemToWatchInfo.Suggestion(owner: owner, comment: suggestionComment)
        }

        let toWatchInfo = WatchlistItemToWatchInfo(date: date, suggestion: toWatchSuggestion)
        let rating = rating > -1 ? rating : nil

        return .watched(info: WatchlistItemWatchedInfo(toWatchInfo: toWatchInfo, rating: rating, date: date))
    }
}
