//
//  Watchlist.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import Foundation
import Combine

struct WatchlistItem {

    let id: WatchlistItemIdentifier
    var state: WatchlistItemState

    init(id: WatchlistItemIdentifier, state: WatchlistItemState) {
        self.id = id
        self.state = state
    }
}

struct WatchlistItemToWatchInfo: Hashable, Equatable {

    struct Suggestion: Hashable, Equatable {
        let owner: String
        let comment: String
    }

    let suggestion: Suggestion?
}

struct WatchlistItemWatchedInfo: Hashable, Equatable {
    let toWatchInfo: WatchlistItemToWatchInfo
    let rating: Double?
    let date: Date
}

enum WatchlistItemState {
    case toWatch(info: WatchlistItemToWatchInfo)
    case watched(info: WatchlistItemWatchedInfo)
}

enum WatchlistItemIdentifier: Identifiable, Hashable, Equatable, Codable {
    case movie(id: Movie.ID)

    var id: AnyHashable {
        switch self {
        case .movie(let id):
            return id
        }
    }
}

@MainActor final class Watchlist: ObservableObject {

    @Published private(set) var items: [WatchlistItem] = []

    init(items: [WatchlistItem]) {
        self.items = items
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
