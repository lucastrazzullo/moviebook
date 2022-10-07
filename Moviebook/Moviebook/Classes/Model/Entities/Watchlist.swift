//
//  Watchlist.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import Foundation

final class Watchlist: ObservableObject {

    enum WatchlistItem: Hashable {
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

    @Published private(set) var toWatch: Set<WatchlistItem>
    @Published private(set) var watched: Set<WatchlistItem>

    init() {
        toWatch = []
        watched = []
    }

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
            toWatch.remove(item)
            watched.remove(item)
        case .toWatch:
            toWatch.insert(item)
            watched.remove(item)
        case .watched:
            toWatch.remove(item)
            watched.insert(item)
        }
    }
}

#if DEBUG
extension Watchlist {

    convenience init(moviesToWatch: [Movie.ID]) {
        self.init()
        self.toWatch = Set(moviesToWatch.map(WatchlistItem.movie(id:)))
    }
}
#endif
