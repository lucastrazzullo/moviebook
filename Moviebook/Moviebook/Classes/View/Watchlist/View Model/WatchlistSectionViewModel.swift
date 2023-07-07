//
//  WatchlistSectionViewModel.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 28/04/2023.
//

import Foundation
import Combine
import MoviebookCommon

@MainActor final class WatchlistSectionViewModel: ObservableObject {

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

        var id: AnyHashable {
            switch self {
            case .movie(_, let watchlistItem):
                return watchlistItem.id
            }
        }
    }

    // MARK: Instance Properties

    @Published var section: Section = .toWatch
    @Published var sorting: Sorting = .lastAdded

    @Published private(set) var isLoading: Bool = true
    @Published private(set) var error: WebServiceError? = nil
    @Published private(set) var items: [Item] = []

    private var watchlistItems: [Section: [Item]] = [:]
    private var subscriptions: Set<AnyCancellable> = []

    // MARK: Internal methods

    func start(watchlist: Watchlist, requestManager: RequestManager) {
        watchlist.$items
            .removeDuplicates()
            .sink { [weak self, weak requestManager] items in
                guard let self, let requestManager else { return }
                Task {
                    await self.updateItems(items, requestManager: requestManager)
                    await self.publishItems(section: self.section, sorting: self.sorting)
                }
            }
            .store(in: &subscriptions)

        Publishers.CombineLatest($section, $sorting)
            .sink { [weak self] section, sorting in
                guard let self else { return }
                Task {
                    await self.publishItems(section: section, sorting: sorting)
                }
            }
            .store(in: &subscriptions)
    }

    // MARK: Private methods - Published items

    private func publishItems(section: Section, sorting: Sorting) async {
        self.items = watchlistItems[section]?.sorted(by: sort(sorting: sorting)) ?? []
    }

    // MARK: Private methods - Watchlist Items

    private func updateItems(_ items: [WatchlistItem], requestManager: RequestManager) async {
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

        await setItemsOrRetry(result, requestManager: requestManager)
    }

    private func setItemsOrRetry(_ items: [Section: [WatchlistItem]], requestManager: RequestManager) async {
        do {
            isLoading = true
            error = nil

            try await set(items: items, requestManager: requestManager)
            isLoading = false

        } catch {
            self.isLoading = false
            self.error = WebServiceError.failedToLoad(id: .init(), retry: { [weak self] in
                Task {
                    await self?.setItemsOrRetry(items, requestManager: requestManager)
                }
            })
        }
    }

    private func set(items: [Section: [WatchlistItem]], requestManager: RequestManager) async throws {
        self.watchlistItems = try await withThrowingTaskGroup(of: Item.self) { group in
            var result = [Section: [Item]]()

            for section in items.keys {
                guard let items = items[section], !items.isEmpty else {
                    continue
                }

                result[section] = []

                for item in items {
                    group.addTask {
                        switch item.id {
                        case .movie(let id):
                            let webService = WebService.movieWebService(requestManager: requestManager)
                            let movie = try await webService.fetchMovie(with: id)
                            return Item.movie(movie: movie, watchlistItem: item)
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

    // MARK: Private methods - Sorting

    private func sort(sorting: Sorting) -> (WatchlistSectionViewModel.Item, WatchlistSectionViewModel.Item) -> Bool {
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

    private func rating(for item: WatchlistSectionViewModel.Item) -> Float {
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

    private func name(for item: WatchlistSectionViewModel.Item) -> String {
        switch item {
        case .movie(let movie, _):
            return movie.details.title
        }
    }

    private func releaseDate(for item: WatchlistSectionViewModel.Item) -> Date {
        switch item {
        case .movie(let movie, _):
            return movie.details.release
        }
    }

    private func addedDate(for item: WatchlistSectionViewModel.Item) -> Date {
        switch item {
        case .movie(_, let watchlistItem):
            return watchlistItem.date
        }
    }
}
