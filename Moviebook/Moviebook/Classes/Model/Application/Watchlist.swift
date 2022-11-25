//
//  Watchlist.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import Foundation

protocol WatchlistStorage {
    func save(watchlist: Watchlist)
    func load(watchlist: Watchlist)
}

@MainActor final class Watchlist: ObservableObject {

    enum WatchlistItem: Hashable, Codable {
        case movie(id: Movie.ID)
    }

    enum WatchlistItemState: Equatable {
        case none
        case toWatch(reason: WatchlistToWatchReason)
        case watched
    }

    var isEmpty: Bool {
        return toWatch.isEmpty && watched.isEmpty
    }

    @Published private(set) var toWatch: [WatchlistItem] = []
    @Published private(set) var watched: [WatchlistItem] = []

    private let storage: WatchlistStorage

    // MARK: Object life cycle

    init(storage: WatchlistStorage) {
        self.storage = storage
        self.storage.load(watchlist: self)
    }

    // MARK: Internal methods

    func itemState(item: WatchlistItem) -> WatchlistItemState {
        if toWatch.contains(item) {
            return .toWatch(reason: .toImplement)
        } else if watched.contains(item) {
            return .watched
        } else {
            return .none
        }
    }

    func update(state: WatchlistItemState, for item: WatchlistItem) {
        Task {
            switch state {
            case .none:
                remove(toWatch: item)
                remove(watched: item)
            case .toWatch:
                remove(watched: item)
                append(toWatch: item)
            case .watched:
                remove(toWatch: item)
                append(watched: item)
            }

            storage.save(watchlist: self)
        }
    }

    func set(toWatchItems: [WatchlistItem]) {
        Task { @MainActor [weak self] in
            self?.toWatch = toWatchItems
        }
    }

    func set(watchedItems: [WatchlistItem]) {
        Task { @MainActor [weak self] in
            self?.watched = watchedItems
        }
    }

    func append(toWatch item: WatchlistItem) {
        Task {
            if !toWatch.contains(item) {
                toWatch.append(item)
            }
        }
    }

    func append(watched item: WatchlistItem) {
        Task {
            if !watched.contains(item) {
                watched.append(item)
            }
        }
    }

    func remove(toWatch item: WatchlistItem) {
        Task {
            if let index = toWatch.firstIndex(of: item) {
                toWatch.remove(at: index)
            }
        }
    }

    func remove(watched item: WatchlistItem) {
        Task {
            if let index = watched.firstIndex(of: item) {
                watched.remove(at: index)
            }
        }
    }
}

final class UserDefaultsWatchlistStorage: WatchlistStorage {

    func save(watchlist: Watchlist) {
        Task {
            do {
                let defaults = UserDefaults.standard
                await defaults.set(try JSONEncoder().encode(watchlist.toWatch), forKey: "Watchlist.toWatch")
                await defaults.set(try JSONEncoder().encode(watchlist.watched), forKey: "Watchlist.watched")
            } catch {
                print(error)
            }
        }
    }

    func load(watchlist: Watchlist) {
        Task {
            do {
                let defaults = UserDefaults.standard
                if let data = defaults.data(forKey: "Watchlist.toWatch") {
                    await watchlist.set(toWatchItems: try JSONDecoder().decode([Watchlist.WatchlistItem].self, from: data))
                }
                if let data = defaults.data(forKey: "Watchlist.watched") {
                    await watchlist.set(watchedItems: try JSONDecoder().decode([Watchlist.WatchlistItem].self, from: data))
                }
            } catch {
                print(error)
            }
        }
    }
}

#if DEBUG
final class InMemoryStorage: WatchlistStorage {

    var toWatch: [Watchlist.WatchlistItem]
    var watched: [Watchlist.WatchlistItem]

    init(toWatch: [Watchlist.WatchlistItem], watched: [Watchlist.WatchlistItem]) {
        self.toWatch = toWatch
        self.watched = watched
    }

    func save(watchlist: Watchlist) {
        Task {
           toWatch = await watchlist.toWatch
           watched = await watchlist.watched
        }
    }

    func load(watchlist: Watchlist) {
        Task {
            await watchlist.set(toWatchItems: toWatch)
            await watchlist.set(watchedItems: watched)
        }
    }
}

extension Watchlist {

    convenience init(moviesToWatch: [Movie.ID]) {
        self.init(storage: InMemoryStorage(toWatch: moviesToWatch.map(WatchlistItem.movie(id:)), watched: []))
    }

    convenience init(watchedMovies: [Movie.ID]) {
        self.init(storage: InMemoryStorage(toWatch: [], watched: watchedMovies.map(WatchlistItem.movie(id:))))
    }
}
#endif
