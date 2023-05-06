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

        func set(items: [WatchlistItemIdentifier], requestManager: RequestManager) {
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
                    self?.sections[.toWatch]?.set(items: itemsToWatch, requestManager: requestManager)
                    self?.sections[.watched]?.set(items: watchedItems, requestManager: requestManager)
                }
            }
            .store(in: &subscriptions)
    }
}
