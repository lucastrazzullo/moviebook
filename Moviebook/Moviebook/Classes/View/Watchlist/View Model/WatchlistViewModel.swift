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

        init?(watchlistState: WatchlistContent.ItemState) {
            switch watchlistState {
            case .toWatch:
                self = .toWatch
            case .watched:
                self = .watched
            default:
                return nil
            }
        }
    }

    enum SectionItem: Identifiable {
        case movie(movie: Movie, section: Section)

        var id: String {
            switch self {
            case .movie(let movie, let section):
                return "\(movie.id): \(section.id)"
            }
        }
    }

    final class SectionContent: ObservableObject, Identifiable {

        let section: Section

        var id: Section.ID {
            return section.id
        }

        var name: String {
            switch section {
            case .toWatch:
                return NSLocalizedString("WATCHLIST.TO_WATCH.TITLE", comment: "")
            case .watched:
                return NSLocalizedString("WATCHLIST.WATCHED.TITLE", comment: "")
            }
        }

        @Published private(set) var items: [SectionItem] = []

        init(section: Section) {
            self.section = section
        }

        func set(items: [WatchlistContent.Item], requestManager: RequestManager) {
            Task {
                let section = self.section
                self.items = await withThrowingTaskGroup(of: SectionItem.self) { group in
                    for item in items {
                        group.addTask {
                            switch item {
                            case .movie(let id):
                                let webService = MovieWebService(requestManager: requestManager)
                                let movie = try await webService.fetchMovie(with: id)
                                return SectionItem.movie(movie: movie, section: section)
                            }
                        }
                    }

                    var results = [SectionItem]()
                    while let result = await group.nextResult() {
                        switch result {
                        case .success(let item):
                            results.append(item)
                        case .failure:
                            break
                        }
                    }
                    return results
                }
            }
        }
    }

    // MARK: Instance Properties

    @Published var sections: [Section: SectionContent] = [:]
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
        watchlist.$content
            .map(\.items)
            .sink { [weak self, weak requestManager] items in
                if let requestManager {
                    self?.update(watchlistItems: items, requestManager: requestManager)
                }
            }
            .store(in: &subscriptions)
    }

    // MARK: Private helper methods

    private func update(watchlistItems: [WatchlistContent.Item: WatchlistContent.ItemState], requestManager: RequestManager) {
        var items = [Section: [WatchlistContent.Item]]()

        sectionIdentifiers.forEach { section in
            items[section] = []
        }

        watchlistItems.forEach { itemTuple in
            let watchlistItemState = itemTuple.value
            let watchlistItem = itemTuple.key

            if let section = Section(watchlistState: watchlistItemState) {
                items[section]?.append(watchlistItem)
            }
        }

        sectionIdentifiers.forEach { section in
            if let items = items[section] {
                sections[section]?.set(items: items, requestManager: requestManager)
            }
        }
    }
}
