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

    enum Item: Hashable, Codable, Identifiable {
        case movie(id: Movie.ID)

        var id: AnyHashable {
            switch self {
            case .movie(let id):
                return id
            }
        }
    }

    enum ItemState: Hashable, Codable {
        case none
        case toWatch(reason: WatchlistToWatchReason)
        case watched(reason: WatchlistToWatchReason, rating: Double)
    }

    var items: [Item: ItemState]

    // MARK: Object life cycle

    static var empty: WatchlistContent {
        return WatchlistContent(items: [:])
    }

    init(items: [Item: ItemState]) {
        self.items = items
    }
}

@MainActor final class Watchlist: ObservableObject {

    @Published private(set) var content: WatchlistContent = WatchlistContent.empty

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

final class FileBasedWatchlistStorage: WatchlistStorage {

    private let fileName: String = "watchlist-v00"

    func save(content: WatchlistContent) {
        do {
            let data = try JSONEncoder().encode(content)
            try storeToFile(data, fileName: fileName)
        } catch {
            print("FileBased Storage -> Failed to save with error:", error)
        }
    }

    func load() -> WatchlistContent {
        do {
            let data = try readFromFile(fileName: fileName)
            return try JSONDecoder().decode(WatchlistContent.self, from: data)
        } catch {
            print("FileBased Storage -> Failed to load with error:", error)
            return WatchlistContent.empty
        }
    }

    // MARK: Private helper methods

    private func storeToFile(_ data: Data, fileName: String) throws {
        let url = itemUrl(fileName: fileName)
        try data.write(to: url)
    }

    private func readFromFile(fileName: String) throws -> Data {
        let url = itemUrl(fileName: fileName)
        return try Data(contentsOf: url)
    }

    private func itemUrl(fileName: String) -> URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return directory[0].appendingPathComponent(fileName)
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
