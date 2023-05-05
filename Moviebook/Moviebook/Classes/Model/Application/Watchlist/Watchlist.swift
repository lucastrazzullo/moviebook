//
//  Watchlist.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import Foundation
import Combine

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

enum WatchlistItemIdentifier: Identifiable, Hashable, Equatable {
    case movie(id: Movie.ID)

    var id: AnyHashable {
        switch self {
        case .movie(let id):
            return id
        }
    }
}

@MainActor final class Watchlist: ObservableObject {

    @Published private(set) var toWatchItems: [WatchlistItemIdentifier: WatchlistItemToWatchInfo]
    @Published private(set) var watchedItems: [WatchlistItemIdentifier: WatchlistItemWatchedInfo]

    private let storage: Storage = Storage()

    init() {
        self.toWatchItems = [:]
        self.watchedItems = [:]

        Task {
            try await storage.load()
        }
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
        remove(itemWith: id)

        switch state {
        case .toWatch(let info):
            toWatchItems[id] = info
        case .watched(let info):
            watchedItems[id] = info
        }
    }

    func remove(itemWith id: WatchlistItemIdentifier) {
        toWatchItems[id] = nil
        watchedItems[id] = nil
    }
}

#if DEBUG
struct WatchlistInMemoryItem {

    let id: WatchlistItemIdentifier
    let state: WatchlistItemState

    init(id: WatchlistItemIdentifier, state: WatchlistItemState) {
        self.id = id
        self.state = state
    }
}

extension Watchlist {

    convenience init(inMemoryItems: [WatchlistInMemoryItem]) {
        self.init()

        inMemoryItems.forEach { item in
            switch item.state {
            case .toWatch(let info):
                self.toWatchItems[item.id] = info
            case .watched(let info):
                self.watchedItems[item.id] = info
            }
        }
    }
}
#endif
