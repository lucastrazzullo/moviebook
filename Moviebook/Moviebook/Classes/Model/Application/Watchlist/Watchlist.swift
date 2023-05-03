//
//  Watchlist.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import Foundation

struct WatchlistItemSuggestion: Hashable, Equatable {
    let owner: String
    let comment: String
}

struct WatchlistItemWatchedInfo: Hashable, Equatable {
    let suggestion: WatchlistItemSuggestion?
    let rating: Double?
    let date: Date
}

enum WatchlistItemState {
    case toWatch(suggestion: WatchlistItemSuggestion?)
    case watched(info: WatchlistItemWatchedInfo)
}

enum WatchlistItemIdentifier: Identifiable, Equatable {
    case movie(id: Movie.ID)

    var id: AnyHashable {
        switch self {
        case .movie(let id):
            return id
        }
    }
}

struct WatchlistItem {
    let id: WatchlistItemIdentifier
    var state: WatchlistItemState
}

@MainActor final class Watchlist: ObservableObject {

    @Published private(set) var items: [WatchlistItem]

    init() {
        self.items = []
    }

    // MARK: Internal methods

    func itemState(id: WatchlistItemIdentifier) -> WatchlistItemState? {
        return items.first(where: { $0.id == id })?.state
    }

    func update(state: WatchlistItemState, forItemWith id: WatchlistItemIdentifier) {
        if let index = items.firstIndex(where: { $0.id == id }) {
            items[index].state = state
        } else {
            items.append(WatchlistItem(id: id, state: state))
        }
    }

    func remove(itemWith id: WatchlistItemIdentifier) {
        if let index = items.firstIndex(where: { $0.id == id }) {
            items.remove(at: index)
        }
    }
}

#if DEBUG
extension Watchlist {

    convenience init(inMemoryItems: [WatchlistItem]) {
        self.init()
        self.items = inMemoryItems
    }
}
#endif
