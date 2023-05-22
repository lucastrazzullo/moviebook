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

    enum SectionItem: Identifiable, Equatable {
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

    final class SectionContent: ObservableObject, Identifiable {

        let section: Section

        var id: Section.ID {
            return section.id
        }

        @Published private(set) var items: [SectionItem] = []

        init(section: Section) {
            self.section = section
        }

        // MARK: Internal methods

        func set(identifiers: [WatchlistItemIdentifier], requestManager: RequestManager) async throws {
            items = try await withThrowingTaskGroup(of: SectionItem.self) { group in
                var result = [WatchlistItemIdentifier: SectionItem]()
                result.reserveCapacity(identifiers.count)

                for identifier in identifiers {
                    group.addTask {
                        switch identifier {
                        case .movie(let id):
                            let webService = MovieWebService(requestManager: requestManager)
                            let movie = try await webService.fetchMovie(with: id)
                            return SectionItem.movie(movie: movie, section: self.section, watchlistIdentifier: identifier)
                        }
                    }
                }

                for try await item in group {
                    result[item.watchlistIdentifier] = item
                }

                var items = [SectionItem]()
                for identifier in identifiers {
                    if let item = result[identifier] {
                        items.append(item)
                    }
                }

                return items
            }
        }
    }

    // MARK: Instance Properties

    @Published private(set) var isLoading: Bool = true
    @Published private(set) var sections: [Section: SectionContent] = [:]
    
    @Published var currentSection: Section = .toWatch

    private var subscriptions: Set<AnyCancellable> = []

    var sectionIdentifiers: [Section] {
        return Section.allCases
    }

    var items: [SectionItem] {
        return sections[currentSection]?.items ?? []
    }

    // MARK: Object life cycle

    init() {
        sectionIdentifiers.forEach { section in
            sections[section] = SectionContent(section: section)
            sections[section]?.objectWillChange
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    self?.objectWillChange.send()
                }
                .store(in: &subscriptions)
        }
    }

    // MARK: Internal methods

    func start(watchlist: Watchlist, requestManager: RequestManager) {
        watchlist.$items
            .sink { [weak self, weak requestManager] items in
                var itemsToWatch = [WatchlistItemIdentifier]()
                var watchedItems = [WatchlistItemIdentifier]()

                for item in items {
                    switch item.state {
                    case .toWatch:
                        itemsToWatch.append(item.id)
                    case .watched:
                        watchedItems.append(item.id)
                    }
                }

                if let requestManager {
                    Task {
                        try await self?.sections[.toWatch]?.set(identifiers: itemsToWatch, requestManager: requestManager)
                        try await self?.sections[.watched]?.set(identifiers: watchedItems, requestManager: requestManager)

                        self?.isLoading = false
                    }
                }
            }
            .store(in: &subscriptions)
    }
}
