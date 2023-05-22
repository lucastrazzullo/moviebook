//
//  Watchlist.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import Foundation
import Combine

struct WatchlistItem: Equatable {

    let id: WatchlistItemIdentifier
    var state: WatchlistItemState

    var date: Date {
        switch state {
        case .toWatch(let info):
            return info.date
        case .watched(let info):
            return info.date
        }
    }

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

    let date: Date
    var suggestion: Suggestion?
}

struct WatchlistItemWatchedInfo: Hashable, Equatable {
    let toWatchInfo: WatchlistItemToWatchInfo
    var rating: Double?
    let date: Date
}

enum WatchlistItemState: Equatable {
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

    let itemWasRemoved: PassthroughSubject<WatchlistItem, Never>
    let itemDidUpdateState: PassthroughSubject<WatchlistItem, Never>
    let itemsDidChange: PassthroughSubject<[WatchlistItem], Never>

    init(items: [WatchlistItem]) {
        self.items = items
        self.itemWasRemoved = PassthroughSubject<WatchlistItem, Never>()
        self.itemDidUpdateState = PassthroughSubject<WatchlistItem, Never>()
        self.itemsDidChange = PassthroughSubject<[WatchlistItem], Never>()
    }

    // MARK: Internal methods

    func itemState(id: WatchlistItemIdentifier) -> WatchlistItemState? {
        return items.first(where: { $0.id == id })?.state
    }

    func update(state: WatchlistItemState, forItemWith id: WatchlistItemIdentifier) {
        if let index = items.firstIndex(where: { $0.id == id }) {
            items[index].state = state
            itemDidUpdateState.send(items[index])
        } else {
            let item = WatchlistItem(id: id, state: state)
            items.append(item)
            itemDidUpdateState.send(item)
        }

        itemsDidChange.send(items)
    }

    func remove(itemWith id: WatchlistItemIdentifier) {
        if let index = items.firstIndex(where: { $0.id == id }) {
            let item = items.remove(at: index)
            itemWasRemoved.send(item)
        }

        itemsDidChange.send(items)
    }

    func set(items: [WatchlistItem]) {
        self.items = items
    }
}
