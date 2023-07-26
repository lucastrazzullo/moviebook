//
//  WatchlistViewSectionContent.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 24/07/2023.
//

import Foundation
import MoviebookCommon

@MainActor final class WatchlistViewSectionContent {

    private(set) var items: [WatchlistViewItem] = []

    let section: WatchlistViewSection

    // MARK: Object life cycle

    init(section: WatchlistViewSection) {
        self.section = section
    }

    // MARK: Internal methods

    func updateItems(_ items: [WatchlistItem], requestLoader: RequestLoader) async throws {
        let filteredItems = items.filter(section.belongsToSection)
        let loadedItems = try await loadItems(filteredItems, requestLoader: requestLoader)
        self.items = loadedItems
    }

    func removeItem(_ identifier: WatchlistItemIdentifier) {
        self.items.removeAll(where: { $0.watchlistItem.id == identifier })
    }

    // MARK: Private methods - Loading

    private func loadItems(_ items: [WatchlistItem], requestLoader: RequestLoader) async throws -> [WatchlistViewItem] {
        return try await withThrowingTaskGroup(of: WatchlistViewItem.self) { group in
            var result = [WatchlistViewItem]()

            for item in items {
                group.addTask {
                    if let existingItem = await self.items.first(where: { $0.watchlistItem == item }) {
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
}
