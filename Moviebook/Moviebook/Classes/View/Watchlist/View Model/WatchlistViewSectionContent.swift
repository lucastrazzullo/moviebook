//
//  WatchlistViewSectionContent.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 24/07/2023.
//

import Foundation
import MoviebookCommon

@MainActor final class WatchlistViewSectionContent {

    private static let storedSortingKey = "watchlistSorting"

    private(set) var sorting: WatchlistViewSorting
    private(set) var items: [WatchlistViewItem] = []

    let section: WatchlistViewSection

    init(section: WatchlistViewSection) {
        self.section = section
        self.sorting = Self.storedSorting() ?? .lastAdded
    }

    // MARK: Internal methods

    func updateSorting(_ sorting: WatchlistViewSorting) {
        guard self.sorting != sorting else { return }
        self.storeSorting(sorting)
        self.sorting = sorting
        self.items = items.sorted(by: sort(sorting: sorting))
    }

    func updateItems(_ items: [WatchlistItem], requestLoader: RequestLoader) async throws {
        let filteredItems = items.filter(section.belongsToSection)
        let loadedItems = try await loadItems(filteredItems, requestLoader: requestLoader)
        let sortedItems = loadedItems.sorted(by: sort(sorting: sorting))
        self.items = sortedItems
    }

    func removeItem(_ identifier: WatchlistItemIdentifier) {
        self.items.removeAll(where: { $0.id == identifier })
    }

    // MARK: Private methods - Loading

    private func loadItems(_ items: [WatchlistItem], requestLoader: RequestLoader) async throws -> [WatchlistViewItem] {
        return try await withThrowingTaskGroup(of: WatchlistViewItem.self) { group in
            var result = [WatchlistViewItem]()

            for item in items {
                group.addTask {
                    if let existingItem = await self.items.first(where: { $0.id == item.id }) {
                        return existingItem
                    } else {
                        return try await self.loadItem(item, requestLoader: requestLoader)
                    }
                }
            }

            for try await item in group {
                result.append(item)
            }

            return result
        }
    }

    private func loadItem(_ item: WatchlistItem, requestLoader: RequestLoader) async throws -> WatchlistViewItem {
        switch item.id {
        case .movie(let id):
            let webService = WebService.movieWebService(requestLoader: requestLoader)
            let movie = try await webService.fetchMovie(with: id)
            return WatchlistViewItem.movie(movie: movie, watchlistItem: item)
        }
    }

    // MARK: Private methods - Sorting

    private func sort(sorting: WatchlistViewSorting) -> (WatchlistViewItem, WatchlistViewItem) -> Bool {
        return { lhs, rhs in
            switch sorting {
            case .lastAdded:
                return self.addedDate(for: lhs) > self.addedDate(for: rhs)
            case .rating:
                return self.rating(for: lhs) > self.rating(for: rhs)
            case .name:
                return self.name(for: lhs) < self.name(for: rhs)
            case .release:
                return self.releaseDate(for: lhs) > self.releaseDate(for: rhs)
            }
        }
    }

    private func rating(for item: WatchlistViewItem) -> Float {
        switch item {
        case .movie(let movie, let watchlistItem):
            switch watchlistItem.state {
            case .toWatch:
                return movie.details.rating.value
            case .watched(let info):
                return Float(info.rating ?? 0)
            }
        }
    }

    private func name(for item: WatchlistViewItem) -> String {
        switch item {
        case .movie(let movie, _):
            return movie.details.title
        }
    }

    private func releaseDate(for item: WatchlistViewItem) -> Date {
        switch item {
        case .movie(let movie, _):
            return movie.details.localisedReleaseDate()
        }
    }

    private func addedDate(for item: WatchlistViewItem) -> Date {
        switch item {
        case .movie(_, let watchlistItem):
            return watchlistItem.date
        }
    }

    // MARK: Private methods - Preferences

    private func storeSorting(_ sorting: WatchlistViewSorting) {
        UserDefaults.standard.set(sorting.rawValue, forKey: Self.storedSortingKey)
    }

    private static func storedSorting() -> WatchlistViewSorting? {
        if let storedSorting = UserDefaults.standard.value(forKey: Self.storedSortingKey) as? String {
            return WatchlistViewSorting(rawValue: storedSorting)
        } else {
            return nil
        }
    }
}
