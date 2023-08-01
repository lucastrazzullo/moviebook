//
//  WatchlistViewSectionContent.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 24/07/2023.
//

import Foundation
import MoviebookCommon

@MainActor final class WatchlistViewSectionContent {

    private var allItems: [WatchlistViewItem] {
        return groups.flatMap(\.items)
    }

    private(set) var groups: [WatchlistViewItemGroup] = []
    private(set) var sorting: WatchlistViewSorting

    let section: WatchlistViewSection

    // MARK: Object life cycle

    init(section: WatchlistViewSection) {
        self.section = section
        self.sorting = Self.persistedSorting(section: section) ?? .lastAdded
    }

    // MARK: Internal methods

    func updateItems(_ items: [WatchlistItem], requestLoader: RequestLoader) async throws {
        let filteredItems = items.filter(section.belongsToSection)
        let loadedItems = try await loadItems(filteredItems, requestLoader: requestLoader)
        let groupedItems = await group(items: loadedItems, sorting: sorting)
        self.groups = groupedItems
    }

    func updateSorting(_ sorting: WatchlistViewSorting) async {
        Self.persist(sorting: sorting, section: section)
        self.sorting = sorting
        self.groups = await group(items: allItems, sorting: sorting)
    }

    func removeItem(_ identifier: WatchlistItemIdentifier) {
        for groupIndex in 0..<groups.count {
            for itemIndex in 0..<groups[groupIndex].items.count {
                switch groups[groupIndex].items[itemIndex] {
                case .movie(let item):
                    if item.watchlistReference == identifier {
                        groups[groupIndex].items.remove(at: itemIndex)
                        return
                    }
                case .movieCollection(let item) where item.items.count == 1:
                    if item.items[0].watchlistReference == identifier {
                        groups[groupIndex].items.remove(at: itemIndex)
                        return
                    }
                case .movieCollection(var item):
                    if let collectionItemIndex = item.items.firstIndex(where: { $0.watchlistReference == identifier }) {
                        item.items.remove(at: collectionItemIndex)

                        groups[groupIndex].items.remove(at: itemIndex)
                        groups[groupIndex].items.insert(.movieCollection(item), at: itemIndex)
                        return
                    }
                }
            }
        }
    }

    // MARK: Private methods - Loading

    private func loadItems(_ items: [WatchlistItem], requestLoader: RequestLoader) async throws -> [WatchlistViewItem] {
        return try await withThrowingTaskGroup(of: WatchlistViewItem.self) { group in
            var result = [WatchlistViewItem]()

            for item in items {
                group.addTask {
                    return try await self.loadItem(item, requestLoader: requestLoader)
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
            let movieItem = WatchlistViewMovieItem(movie: movie, watchlistItem: item)

            if let collection = movie.collection,
               let collectionItem = WatchlistViewMovieCollectionItem(collection: collection, items: [movieItem]) {
                return WatchlistViewItem.movieCollection(collectionItem)
            } else {
                return WatchlistViewItem.movie(movieItem)
            }
        }
    }

    // MARK: Private methods - Grouping

    private func group(items: [WatchlistViewItem], sorting: WatchlistViewSorting) async -> [WatchlistViewItemGroup] {
        var collectionItems: [MovieCollection: [WatchlistViewMovieItem]] = [:]
        for item in items {
            if case .movieCollection(let collectionItem) = item {
                if collectionItems[collectionItem.collection] == nil {
                    collectionItems[collectionItem.collection] = collectionItem.items
                } else {
                    collectionItems[collectionItem.collection]?.append(contentsOf: collectionItem.items)
                }
            }
        }

        var items: [WatchlistViewItem] = items.filter { item in
            if case .movieCollection = item {
                return false
            } else {
                return true
            }
        }

        for movieCollection in collectionItems.keys {
            if let movieCollectionItems = collectionItems[movieCollection]?.sorted(by: { $0.releaseDate < $1.releaseDate }), let collectionItem = WatchlistViewMovieCollectionItem(collection: movieCollection, items: movieCollectionItems) {
                items.append(.movieCollection(collectionItem))
            }
        }

        switch sorting {
        case .lastAdded:
            return await makeLastAddedSections(items: items)
        case .rating:
            return await makeRatingSections(items: items)
        case .name:
            return await makeNameSections(items: items)
        case .release:
            return await makeReleaseSections(items: items)
        }
    }

    private func makeLastAddedSections(items: [WatchlistViewItem]) async -> [WatchlistViewItemGroup] {
        var lastWeekItems: [WatchlistViewItem] = []
        var lastMonthItems: [WatchlistViewItem] = []
        var lastYearItems: [WatchlistViewItem] = []
        var allOtherItems: [WatchlistViewItem] = []

        for item in items {
            if Calendar.current.isDate(item.addedDate, equalTo: .now, toGranularity: .weekOfMonth) {
                lastWeekItems.append(item)
            } else if Calendar.current.isDate(item.addedDate, equalTo: .now, toGranularity: .month) {
                lastMonthItems.append(item)
            } else if Calendar.current.isDate(item.addedDate, equalTo: .now, toGranularity: .year) {
                lastYearItems.append(item)
            } else {
                allOtherItems.append(item)
            }
        }

        var sections: [WatchlistViewItemGroup] = []

        if !lastWeekItems.isEmpty {
            sections.append(WatchlistViewItemGroup(title: "Added last week", icon: "calendar.badge.plus", items: lastWeekItems))
        }
        if !lastMonthItems.isEmpty {
            sections.append(WatchlistViewItemGroup(title: "Added last month", icon: "calendar.badge.plus", items: lastMonthItems))
        }
        if !lastYearItems.isEmpty {
            sections.append(WatchlistViewItemGroup(title: "Added last year", icon: "calendar.badge.plus", items: lastYearItems))
        }
        if !allOtherItems.isEmpty {
            sections.append(WatchlistViewItemGroup(title: "Added earlier", icon: "calendar.badge.plus", items: allOtherItems))
        }

        return sections
    }

    private func makeRatingSections(items: [WatchlistViewItem]) async -> [WatchlistViewItemGroup] {
        var highRatingItems: [WatchlistViewItem] = []
        var averageRatingItems: [WatchlistViewItem] = []
        var lowRatingItems: [WatchlistViewItem] = []
        var unratedItems: [WatchlistViewItem] = []

        for item in items {
            if item.rating.percentage > 0.7 {
                highRatingItems.append(item)
            } else if item.rating.percentage > 0.5 {
                averageRatingItems.append(item)
            } else if item.rating.percentage > 0 {
                lowRatingItems.append(item)
            } else {
                unratedItems.append(item)
            }
        }

        var sections: [WatchlistViewItemGroup] = []

        if !highRatingItems.isEmpty {
            sections.append(WatchlistViewItemGroup(title: "Highly rated", icon: "star.square.on.square.fill", items: highRatingItems))
        }
        if !averageRatingItems.isEmpty {
            sections.append(WatchlistViewItemGroup(title: "Average", icon: "star.leadinghalf.filled", items: averageRatingItems))
        }
        if !lowRatingItems.isEmpty {
            sections.append(WatchlistViewItemGroup(title: "Low rated", icon: "star.slash.fill", items: lowRatingItems))
        }
        if !unratedItems.isEmpty {
            sections.append(WatchlistViewItemGroup(title: "Not rated", icon: "pencil.tip.crop.circle.badge.plus", items: unratedItems))
        }

        return sections
    }

    private func makeNameSections(items: [WatchlistViewItem]) async -> [WatchlistViewItemGroup] {
        let sortedItems = items.sorted(by: { $0.name < $1.name })
        return [
            WatchlistViewItemGroup(title: "Alphabetical order", icon: "a.square.fill", items: sortedItems)
        ]
    }

    private func makeReleaseSections(items: [WatchlistViewItem]) async -> [WatchlistViewItemGroup] {
        var yearsMapping: [Int: [WatchlistViewItem]] = [:]

        for item in items {
            guard let year = Calendar.current.dateComponents([.year], from: item.releaseDate).year else {
                continue
            }

            if yearsMapping[year] == nil {
                yearsMapping[year] = []
            }

            yearsMapping[year]?.append(item)
        }

        return yearsMapping.keys.sorted(by: >).map { year in
            WatchlistViewItemGroup(title: "Released in \(year)", icon: "calendar", items: yearsMapping[year]!)
        }
    }

    // MARK: Private methods - Persisting

    private static func persist(sorting: WatchlistViewSorting, section: WatchlistViewSection) {
        UserDefaults.standard.set(sorting.rawValue, forKey: "\(section.id)-sorting")
    }

    private static func persistedSorting(section: WatchlistViewSection) -> WatchlistViewSorting? {
        guard let rawValue = UserDefaults.standard.object(forKey: "\(section.id)-sorting") as? String else {
            return nil
        }
        return WatchlistViewSorting(rawValue: rawValue)
    }
}
