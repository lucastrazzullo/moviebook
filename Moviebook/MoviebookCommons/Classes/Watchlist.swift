//
//  Watchlist.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import Foundation
import Combine

public struct WatchlistItem: Equatable {

    public let id: WatchlistItemIdentifier
    public var state: WatchlistItemState

    public var date: Date {
        switch state {
        case .toWatch(let info):
            return info.date
        case .watched(let info):
            return info.date
        }
    }

    public init(id: WatchlistItemIdentifier, state: WatchlistItemState) {
        self.id = id
        self.state = state
    }
}

public struct WatchlistItemToWatchInfo: Hashable, Equatable {

    public struct Suggestion: Hashable, Equatable {
        public let owner: String
        public let comment: String

        public init(owner: String, comment: String) {
            self.owner = owner
            self.comment = comment
        }
    }

    public let date: Date
    public var suggestion: Suggestion?

    public init(date: Date, suggestion: Suggestion? = nil) {
        self.date = date
        self.suggestion = suggestion
    }
}

public struct WatchlistItemWatchedInfo: Hashable, Equatable {
    public let toWatchInfo: WatchlistItemToWatchInfo
    public var rating: Double?
    public let date: Date

    public init(toWatchInfo: WatchlistItemToWatchInfo, rating: Double? = nil, date: Date) {
        self.toWatchInfo = toWatchInfo
        self.rating = rating
        self.date = date
    }
}

public enum WatchlistItemState: Equatable {
    case toWatch(info: WatchlistItemToWatchInfo)
    case watched(info: WatchlistItemWatchedInfo)
}

public enum WatchlistItemIdentifier: Identifiable, Hashable, Equatable, Codable {
    case movie(id: Movie.ID)

    public var id: AnyHashable {
        switch self {
        case .movie(let id):
            return id
        }
    }
}

@MainActor public final class Watchlist: ObservableObject {

    @Published public private(set) var items: [WatchlistItem] = []

    public let itemWasRemoved: PassthroughSubject<WatchlistItem, Never>
    public let itemDidUpdateState: PassthroughSubject<WatchlistItem, Never>
    public let itemsDidChange: PassthroughSubject<[WatchlistItem], Never>

    public init(items: [WatchlistItem]) {
        self.items = items
        self.itemWasRemoved = PassthroughSubject<WatchlistItem, Never>()
        self.itemDidUpdateState = PassthroughSubject<WatchlistItem, Never>()
        self.itemsDidChange = PassthroughSubject<[WatchlistItem], Never>()
    }

    // MARK: Internal methods

    func set(items: [WatchlistItem]) {
        self.items = items
    }

    // MARK: Public methods

    public func itemState(id: WatchlistItemIdentifier) -> WatchlistItemState? {
        return items.first(where: { $0.id == id })?.state
    }

    public func update(state: WatchlistItemState, forItemWith id: WatchlistItemIdentifier) {
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

    public func remove(itemWith id: WatchlistItemIdentifier) {
        if let index = items.firstIndex(where: { $0.id == id }) {
            let item = items.remove(at: index)
            itemWasRemoved.send(item)
        }

        itemsDidChange.send(items)
    }
}
