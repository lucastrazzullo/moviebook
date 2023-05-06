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
    let state: WatchlistItemState

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

    let didUpdatePublisher = PassthroughSubject<[WatchlistItem], Never>()

    @Published private(set) var toWatchItems: [WatchlistItemIdentifier: WatchlistItemToWatchInfo]
    @Published private(set) var watchedItems: [WatchlistItemIdentifier: WatchlistItemWatchedInfo]

    init(items: [WatchlistItem]) {
        self.toWatchItems = [:]
        self.watchedItems = [:]
        self.set(items: items)
    }

    // MARK: Internal methods

    func itemState(id: WatchlistItemIdentifier) -> WatchlistItemState? {
        if let info = toWatchItems[id] {
            return .toWatch(info: info)
        }
        if let info = watchedItems[id] {
            return .watched(info: info)
        }

        return nil
    }

    func update(state: WatchlistItemState, forItemWith id: WatchlistItemIdentifier) {
        switch state {
        case .toWatch(let info):
            toWatchItems[id] = info
            watchedItems[id] = nil
        case .watched(let info):
            toWatchItems[id] = nil
            watchedItems[id] = info
        }

        didUpdatePublisher.send(makeItems())
    }

    func remove(itemWith id: WatchlistItemIdentifier) {
        toWatchItems[id] = nil
        watchedItems[id] = nil

        didUpdatePublisher.send(makeItems())
    }

    // MARK: Private helper methods

    private func set(items: [WatchlistItem]) {
        items.forEach { item in
            switch item.state {
            case .toWatch(let info):
                toWatchItems[item.id] = info
            case .watched(let info):
                watchedItems[item.id] = info
            }
        }
    }

    private func makeItems() -> [WatchlistItem] {
        var result = [WatchlistItem]()

        for toWatchIdentifier in toWatchItems.keys {
            if let info = toWatchItems[toWatchIdentifier] {
                result.append(WatchlistItem(id: toWatchIdentifier, state: .toWatch(info: info)))
            }
        }

        for watchedIdentifier in watchedItems.keys {
            if let info = watchedItems[watchedIdentifier] {
                result.append(WatchlistItem(id: watchedIdentifier, state: .watched(info: info)))
            }
        }

        return result
    }
}
