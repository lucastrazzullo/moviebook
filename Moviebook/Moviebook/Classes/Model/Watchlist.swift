//
//  Watchlist.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import Foundation

final class Watchlist: ObservableObject {

    enum WatchlistItem: Hashable, Codable {
        case movie(id: Movie.ID)
    }

    enum WatchlistItemState {
        case none
        case toWatch
        case watched
    }

    var isEmpty: Bool {
        return toWatch.isEmpty && watched.isEmpty
    }

    @Published private(set) var toWatch: [WatchlistItem]
    @Published private(set) var watched: [WatchlistItem]

    // MARK: Object life cycle

    init() {
        toWatch = []
        watched = []
        load()
    }

    // MARK: Internal methods

    func itemState(item: WatchlistItem) -> WatchlistItemState {
        if toWatch.contains(item) {
            return .toWatch
        } else if watched.contains(item) {
            return .watched
        } else {
            return .none
        }
    }

    func update(state: WatchlistItemState, for item: WatchlistItem) {
        switch state {
        case .none:
            if let index = toWatch.firstIndex(of: item) {
                toWatch.remove(at: index)
            }
            if let index = watched.firstIndex(of: item) {
                watched.remove(at: index)
            }
        case .toWatch:
            if let index = watched.firstIndex(of: item) {
                watched.remove(at: index)
            }
            if !toWatch.contains(item) {
                toWatch.append(item)
            }
        case .watched:
            if let index = toWatch.firstIndex(of: item) {
                toWatch.remove(at: index)
            }
            if !watched.contains(item) {
                watched.append(item)
            }
        }

        save()
    }

    // MARK: Private methods

    private func save() {
        do {
            let defaults = UserDefaults.standard
            defaults.set(try JSONEncoder().encode(toWatch), forKey: "Watchlist.toWatch")
            defaults.set(try JSONEncoder().encode(watched), forKey: "Watchlist.watched")
        } catch {
            print(error)
        }
    }

    private func load() {
        do {
            let defaults = UserDefaults.standard
            if let data = defaults.data(forKey: "Watchlist.toWatch") {
                toWatch = try JSONDecoder().decode([WatchlistItem].self, from: data)
            }
            if let data = defaults.data(forKey: "Watchlist.watched") {
                watched = try JSONDecoder().decode([WatchlistItem].self, from: data)
            }

        } catch {
            print(error)
        }
    }
}

#if DEBUG
extension Watchlist {

    convenience init(moviesToWatch: [Movie.ID]) {
        self.init()
        self.toWatch = moviesToWatch.map(WatchlistItem.movie(id:))
    }

    convenience init(watchedMovies: [Movie.ID]) {
        self.init()
        self.watched = watchedMovies.map(WatchlistItem.movie(id:))
    }
}
#endif
