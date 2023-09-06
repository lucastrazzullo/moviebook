//
//  Favourites.swift
//  MoviebookCommon
//
//  Created by Luca Strazzullo on 20/08/2023.
//

import Foundation
import Combine

public enum FavouriteItemIdentifier: Identifiable, Hashable, Equatable, Codable {
    case artist(id: Artist.ID)

    public var id: AnyHashable {
        switch self {
        case .artist(let id):
            return id
        }
    }
}

public enum FavouriteItemState: Int16, Equatable, Hashable {
    case pinned = 1
}

public struct FavouriteItem: Equatable, Hashable {
    public let id: FavouriteItemIdentifier
    public var state: FavouriteItemState

    public init(id: FavouriteItemIdentifier, state: FavouriteItemState) {
        self.id = id
        self.state = state
    }
}

@MainActor public final class Favourites: ObservableObject {

    public private(set) var items: [FavouriteItem] = []

    public let itemWasRemoved: PassthroughSubject<FavouriteItem, Never>
    public let itemDidUpdateState: PassthroughSubject<FavouriteItem, Never>
    public let itemsDidChange: PassthroughSubject<[FavouriteItem], Never>

    public init(items: [FavouriteItem]) {
        self.items = items
        self.itemWasRemoved = PassthroughSubject<FavouriteItem, Never>()
        self.itemDidUpdateState = PassthroughSubject<FavouriteItem, Never>()
        self.itemsDidChange = PassthroughSubject<[FavouriteItem], Never>()
    }

    // MARK: Public methods

    public func itemState(id: FavouriteItemIdentifier) -> FavouriteItemState? {
        return items.first(where: { $0.id == id })?.state
    }

    public func update(state: FavouriteItemState, forItemWith id: FavouriteItemIdentifier) {
        objectWillChange.send()

        if let index = items.firstIndex(where: { $0.id == id }) {
            items[index].state = state
            itemDidUpdateState.send(items[index])
        } else {
            let item = FavouriteItem(id: id, state: state)
            items.append(item)
            itemDidUpdateState.send(item)
        }

        itemsDidChange.send(items)
    }

    public func remove(itemWith id: FavouriteItemIdentifier) {
        objectWillChange.send()

        if let index = items.firstIndex(where: { $0.id == id }) {
            let item = items.remove(at: index)
            itemWasRemoved.send(item)
        }

        itemsDidChange.send(items)
    }
}
