//
//  WatchlistSectionViewModel.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 28/04/2023.
//

import Foundation
import Combine
import MoviebookCommon

@MainActor final class WatchlistViewModel: ObservableObject {

    // MARK: Types

    enum Section: String, Identifiable, Hashable, Equatable, CaseIterable {
        case toWatch
        case watched

        var id: String {
            return self.rawValue
        }

        var name: String {
            switch self {
            case .toWatch:
                return NSLocalizedString("WATCHLIST.TO_WATCH.TITLE", comment: "")
            case .watched:
                return NSLocalizedString("WATCHLIST.WATCHED.TITLE", comment: "")
            }
        }
    }

    enum Sorting: String, CaseIterable, Hashable, Equatable {
        case lastAdded
        case rating
        case name
        case release

        var label: String {
            switch self {
            case .lastAdded:
                return "Last added"
            case .rating:
                return "Rating"
            case .name:
                return "Name"
            case .release:
                return "Release"
            }
        }

        var image: String {
            switch self {
            case .lastAdded:
                return "text.line.first.and.arrowtriangle.forward"
            case .rating:
                return "star"
            case .name:
                return "a.circle.fill"
            case .release:
                return "calendar"
            }
        }
    }

    enum Item: Identifiable, Equatable {
        case movie(movie: Movie, watchlistItem: WatchlistItem)

        var id: WatchlistItemIdentifier {
            switch self {
            case .movie(_, let watchlistItem):
                return watchlistItem.id
            }
        }
    }

    // MARK: Type properties

    private static let storedSectionKey = "watchlistSection"
    private static let storedSortingKey = "watchlistSorting"

    // MARK: Instance Properties

    @Published var section: Section
    @Published var sorting: Sorting

    @Published private(set) var isLoading: Bool = true
    @Published private(set) var error: WebServiceError? = nil
    @Published private(set) var items: [Item] = []

    private var allItems: [Section: [Item]] = [:]
    private var subscriptions: Set<AnyCancellable> = []

    // MARK: Object life cycle

    init() {
        if let storedSection = UserDefaults.standard.value(forKey: Self.storedSectionKey) as? String {
            self.section = Section(rawValue: storedSection) ?? .toWatch
        } else {
            self.section = .toWatch
        }

        if let storedSorting = UserDefaults.standard.value(forKey: Self.storedSortingKey) as? String {
            self.sorting = Sorting(rawValue: storedSorting) ?? .lastAdded
        } else {
            self.sorting = .lastAdded
        }
    }

    // MARK: Internal methods

    func start(watchlist: Watchlist, requestManager: RequestManager) async {
        await loadItems(watchlist.items, requestManager: requestManager)

        watchlist.itemWasRemoved
            .sink { [weak self] item in
                guard let self else { return }
                Task {
                    await self.removeItemAndPublish(item)
                }
            }
            .store(in: &subscriptions)

        watchlist.itemsDidChange
            .removeDuplicates()
            .sink { [weak self, weak requestManager] items in
                guard let self, let requestManager else { return }
                Task {
                    let arrangedItems = await self.arrangedItems(items)
                    let items = try await self.loadedItems(arrangedItems, requestManager: requestManager)
                    self.updateAndPublishItems(items: items)
                }
            }
            .store(in: &subscriptions)

        Publishers.CombineLatest($section, $sorting)
            .sink { [weak self] section, sorting in
                guard let self else { return }

                UserDefaults.standard.set(section.rawValue, forKey: Self.storedSectionKey)
                UserDefaults.standard.set(sorting.rawValue, forKey: Self.storedSortingKey)

                self.publishItems(section: section, sorting: sorting)
            }
            .store(in: &subscriptions)
    }

    // MARK: Private methods - Data flow

    private func loadItems(_ items: [WatchlistItem], requestManager: RequestManager) async {
        do {
            isLoading = true
            error = nil

            let arrangedItems = await arrangedItems(items)
            let items = try await loadedItems(arrangedItems, requestManager: requestManager)
            updateAndPublishItems(items: items)

            isLoading = false

        } catch {
            self.isLoading = false
            self.error = WebServiceError.failedToLoad(id: .init(), retry: { [weak self] in
                Task {
                    await self?.loadItems(items, requestManager: requestManager)
                }
            })
        }
    }

    private func removeItemAndPublish(_ item: WatchlistItem) async {
        for section in allItems.keys {
            if let index = allItems[section]?.firstIndex(where: { $0.id == item.id }) {
                allItems[section]?.remove(at: index)
                continue
            }
        }
        publishItems(section: section, sorting: sorting)
    }

    private func updateAndPublishItems(items: [Section: [Item]]) {
        allItems = items
        publishItems(section: section, sorting: sorting)
    }

    private func publishItems(section: Section, sorting: Sorting) {
        items = allItems[section]?.sorted(by: sort(sorting: sorting)) ?? []
    }

    // MARK: Private methods - Data manipulation

    private func arrangedItems(_ items: [WatchlistItem]) async -> [Section: [WatchlistItem]] {
        var result = [Section: [WatchlistItem]]()
        for section in Section.allCases {
            result[section] = []
        }

        for item in items {
            switch item.state {
            case .toWatch:
                result[.toWatch]?.append(item)
            case .watched:
                result[.watched]?.append(item)
            }
        }

        return result
    }

    private func loadedItems(_ items: [Section: [WatchlistItem]], requestManager: RequestManager) async throws -> [Section: [Item]] {
        return try await withThrowingTaskGroup(of: Item.self) { group in
            var result = [Section: [Item]]()

            for section in items.keys {
                guard let items = items[section], !items.isEmpty else {
                    continue
                }

                result[section] = []

                for item in items {
                    group.addTask {
                        if let cachedItem = await self.loadFromExistingItems(item: item) {
                            return cachedItem
                        } else {
                            switch item.id {
                            case .movie(let id):
                                let webService = WebService.movieWebService(requestManager: requestManager)
                                let movie = try await webService.fetchMovie(with: id)
                                return Item.movie(movie: movie, watchlistItem: item)
                            }
                        }
                    }
                }

                for try await item in group {
                    result[section]?.append(item)
                }
            }

            return result
        }
    }

    private func loadFromExistingItems(item: WatchlistItem) async -> Item? {
        for section in allItems.keys {
            if let index = allItems[section]?.firstIndex(where: { $0.id == item.id }) {
                return allItems[section]?[index]
            }
        }
        return nil
    }

    // MARK: Private methods - Sorting

    private func sort(sorting: Sorting) -> (WatchlistViewModel.Item, WatchlistViewModel.Item) -> Bool {
        return { lhs, rhs in
            switch sorting {
            case .lastAdded:
                return self.addedDate(for: lhs) > self.addedDate(for: rhs)
            case .rating:
                return self.rating(for: lhs) > self.rating(for: rhs)
            case .name:
                return self.name(for: lhs) < self.name(for: rhs)
            case .release:
                return self.releaseDate(for: lhs) < self.releaseDate(for: rhs)
            }
        }
    }

    private func rating(for item: WatchlistViewModel.Item) -> Float {
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

    private func name(for item: WatchlistViewModel.Item) -> String {
        switch item {
        case .movie(let movie, _):
            return movie.details.title
        }
    }

    private func releaseDate(for item: WatchlistViewModel.Item) -> Date {
        switch item {
        case .movie(let movie, _):
            return movie.details.release
        }
    }

    private func addedDate(for item: WatchlistViewModel.Item) -> Date {
        switch item {
        case .movie(_, let watchlistItem):
            return watchlistItem.date
        }
    }
}
