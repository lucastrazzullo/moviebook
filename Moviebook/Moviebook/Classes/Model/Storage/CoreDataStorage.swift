//
//  CoreDataStorage.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 20/08/2023.
//

import Foundation
import CoreData

protocol CoreDataStoreableItem {
    var identifier: Data? { get }
    func store(in managedObject: NSManagedObject, with identifier: Data)
}

protocol CoreDataStoredItem: NSManagedObject {
    var identifier: Data? { get }
}

actor CoreDataStorage {

    private let persistentContainer: NSPersistentContainer

    init() async throws {
        persistentContainer = NSPersistentCloudKitContainer(name: "Moviebook")
        try await load()
    }

    // MARK: - Internal methods

    func fetch<Item: CoreDataStoredItem>() async throws -> [Item] {
        let task = Task { @MainActor in
            let fetchRequest = Item.fetchRequest()
            return try persistentContainer.viewContext.fetch(fetchRequest)
        }

        return try await task.value
            .compactMap { $0 as? Item }
            .removeDuplicates { $0.identifier == $1.identifier }
    }

    func store<StoringItem: CoreDataStoreableItem, StoredItem: CoreDataStoredItem>(items: [StoringItem], storedType: StoredItem.Type) async throws {

        // Remove items that were deleted from watchlist
        let storedItems: [StoredItem] = try await fetch()
        for storedItem in storedItems {
            guard let identifier = storedItem.identifier, items.contains(where: { $0.identifier == identifier }) else {
                delete(storedWatchlistItem: storedItem)
                continue
            }
        }

        // Add or modify existing items
        for itemToStore in items.removeDuplicates(where: { $0.identifier == $1.identifier }) {
            guard let identifier = itemToStore.identifier else { continue }

            let managedItemToStore = storedItems.first(where: { $0.identifier == identifier })
                ?? storedType.init(context: persistentContainer.viewContext)

            itemToStore.store(in: managedItemToStore, with: identifier)
        }
    }

    func save() {
        Task { @MainActor in
            do {
                try persistentContainer.viewContext.save()
            } catch {
                persistentContainer.viewContext.rollback()
                print("Failed to save context: \(error)")
            }
        }
    }

    // MARK: - Private methods

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

    private func delete<Item: CoreDataStoredItem>(storedWatchlistItem: Item) {
        Task { @MainActor in
            persistentContainer.viewContext.delete(storedWatchlistItem)
        }
    }
}
