//
//  WatchlistViewModel.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 28/04/2023.
//

import Foundation
import Combine

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

    enum Item: Identifiable, Equatable {
        case movie(movie: Movie, section: Section, watchlistIdentifier: WatchlistItemIdentifier)

        var id: String {
            switch self {
            case .movie(let movie, let section, _):
                return "\(movie.id): \(section.name)"
            }
        }

        var section: Section {
            switch self {
            case .movie(_, let section, _):
                return section
            }
        }

        var watchlistIdentifier: WatchlistItemIdentifier {
            switch self {
            case .movie(_, _, let watchlistIdentifier):
                return watchlistIdentifier
            }
        }
    }

    // MARK: Instance Properties

    @Published private(set) var isLoading: Bool = true
    @Published private(set) var items: [Item] = []

    private var subscriptions: Set<AnyCancellable> = []

    // MARK: Internal methods

    func start(section: Section, watchlist: Watchlist, requestManager: RequestManager) {
        watchlist.$items
            .sink { [weak self, weak requestManager] items in
                var itemIdentifiers = [WatchlistItemIdentifier]()

                for item in items {
                    switch (item.state, section) {
                    case (.toWatch, .toWatch):
                        itemIdentifiers.append(item.id)
                    case (.watched, .watched):
                        itemIdentifiers.append(item.id)
                    default:
                        continue
                    }
                }

                if let requestManager {
                    Task {
                        try await self?.set(identifiers: itemIdentifiers, section: section, requestManager: requestManager)
                        self?.isLoading = false
                    }
                }
            }
            .store(in: &subscriptions)
    }

    private func set(identifiers: [WatchlistItemIdentifier], section: Section, requestManager: RequestManager) async throws {
        items = try await withThrowingTaskGroup(of: Item.self) { group in
            var result = [WatchlistItemIdentifier: Item]()
            result.reserveCapacity(identifiers.count)

            for identifier in identifiers {
                group.addTask {
                    switch identifier {
                    case .movie(let id):
                        let webService = MovieWebService(requestManager: requestManager)
                        let movie = try await webService.fetchMovie(with: id)
                        return Item.movie(movie: movie, section: section, watchlistIdentifier: identifier)
                    }
                }
            }

            for try await item in group {
                result[item.watchlistIdentifier] = item
            }

            var items = [Item]()
            for identifier in identifiers {
                if let item = result[identifier] {
                    items.append(item)
                }
            }

            return items
        }
    }
}
