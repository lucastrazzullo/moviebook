//
//  Watchlist.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import Foundation

protocol WatchlistStorage {
    func save(content: WatchlistContent)
    func load() -> WatchlistContent
}

struct WatchlistContent: Codable {

    enum Item: Hashable, Codable {
        case movie(id: Movie.ID)
    }

    enum ItemState: Hashable, Codable {
        case none
        case toWatch(reason: WatchlistToWatchReason)
        case watched
    }

    var items: [Item: ItemState] = [:]
}

@MainActor final class Watchlist: ObservableObject {

    @Published private(set) var content: WatchlistContent = WatchlistContent()

    private let storage: WatchlistStorage

    // MARK: Object life cycle

    init(storage: WatchlistStorage) {
        self.storage = storage
        self.content = storage.load()
    }

    // MARK: Internal methods

    func itemState(item: WatchlistContent.Item) -> WatchlistContent.ItemState {
        guard let itemState = content.items[item] else {
            return .none
        }
        return itemState
    }

    func update(state: WatchlistContent.ItemState, for item: WatchlistContent.Item) {
        Task { [weak self] in
            guard let self = self else { return }
            self.content.items[item] = state
            self.storage.save(content: self.content)
        }
    }
}

final class UserDefaultsWatchlistStorage: WatchlistStorage {

    enum Error: Swift.Error {
        case itemsNotFound
    }

    func save(content: WatchlistContent) {
        do {
            let defaults = UserDefaults.standard
            defaults.set(try JSONEncoder().encode(content), forKey: "Watchlist.content")
        } catch {
            print(error)
        }
    }

    func load() -> WatchlistContent {
        do {
            let defaults = UserDefaults.standard
            if let data = defaults.data(forKey: "Watchlist.content") {
                let content =  try JSONDecoder().decode(WatchlistContent.self, from: data)
                return content
            } else {
                throw Error.itemsNotFound
            }
        } catch {
            print(error)
            return WatchlistContent()
        }
    }
}

#if DEBUG
final class InMemoryStorage: WatchlistStorage {

    private var content: WatchlistContent

    init(content: WatchlistContent) {
        self.content = content
    }

    func save(content: WatchlistContent) {
        self.content = content
    }

    func load() -> WatchlistContent {
        return content
    }
}

extension Watchlist {

    convenience init(items: [WatchlistContent.Item: WatchlistContent.ItemState]) {
        let content = WatchlistContent(items: items)
        self.init(storage: InMemoryStorage(content: content))
    }
}
#endif
