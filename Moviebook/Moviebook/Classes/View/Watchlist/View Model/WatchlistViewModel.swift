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
        case movie(movie: Movie, section: Section, watchlistIdentifier: WatchlistItemIdentifier, addedDate: Date)

        var id: String {
            switch self {
            case .movie(let movie, let section, _, _):
                return "\(movie.id): \(section.name)"
            }
        }

        var section: Section {
            switch self {
            case .movie(_, let section, _, _):
                return section
            }
        }

        var watchlistIdentifier: WatchlistItemIdentifier {
            switch self {
            case .movie(_, _, let watchlistIdentifier, _):
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
            .removeDuplicates()
            .sink { [weak self, weak requestManager] items in
                var result = [WatchlistItem]()

                for item in items {
                    switch (item.state, section) {
                    case (.toWatch, .toWatch):
                        result.append(item)
                    case (.watched, .watched):
                        result.append(item)
                    default:
                        continue
                    }
                }

                if let requestManager {
                    Task {
                        try await self?.set(items: result, section: section, requestManager: requestManager)
                        self?.isLoading = false
                    }
                }
            }
            .store(in: &subscriptions)
    }

    private func set(items: [WatchlistItem], section: Section, requestManager: RequestManager) async throws {
        self.items = try await withThrowingTaskGroup(of: Item.self) { group in
            var result = [Item]()
            result.reserveCapacity(items.count)

            for item in items {
                group.addTask {
                    switch item.id {
                    case .movie(let id):
                        let webService = MovieWebService(requestManager: requestManager)
                        let movie = try await webService.fetchMovie(with: id)
                        return Item.movie(movie: movie, section: section, watchlistIdentifier: item.id, addedDate: item.date)
                    }
                }
            }

            for try await item in group {
                result.append(item)
            }

            return result
        }
    }
}
