//
//  WatchlistViewModel.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 28/04/2023.
//

import Foundation
import Combine
import MoviebookCommons

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

    enum Sorting: CaseIterable {
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

        var rating: Float {
            switch self {
            case .movie(let movie, _, _):
                return movie.details.rating.value
            }
        }

        var name: String {
            switch self {
            case .movie(let movie, _, _):
                return movie.details.title
            }
        }

        var release: Date {
            switch self {
            case .movie(let movie, _, _):
                return movie.details.release
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
            .removeDuplicates()
            .sink { [weak self, weak requestManager] items in
                var itemIdentifiers = [WatchlistItemIdentifier]()

                for item in items.sorted(by: { lhs, rhs in lhs.date > rhs.date }) {
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
