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

        private var hiddenItemIndex: Int?

        init(section: Section) {
            self.section = section
        }

        // MARK: Internal methods

        func set(identifiers: [WatchlistItemIdentifier], requestManager: RequestManager) async throws {
            hiddenItemIndex = nil

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

        func hide(item: SectionItem) {
            guard let index = items.firstIndex(of: item) else {
                return
            }

            hiddenItemIndex = index
            items.remove(at: index)
        }

        func unhide(item: SectionItem) {
            guard let index = hiddenItemIndex else {
                return
            }

            items.insert(item, at: index)
            hiddenItemIndex = nil
        }
    }

    // MARK: Instance Properties

    @Published private(set) var isLoading: Bool = true
    @Published private(set) var sections: [Section: SectionContent] = [:]
    @Published private(set) var itemToRemove: SectionItem?
    @Published private(set) var undoTimeRemaining: TimeInterval = 0
    
    @Published var currentSection: Section = .toWatch

    private var undoTimer: Publishers.Autoconnect<Timer.TimerPublisher>?
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

    func remove(item: SectionItem, from watchlist: Watchlist) {
        sections[item.section]?.hide(item: item)

        itemToRemove = item
        undoTimeRemaining = 5

        undoTimer = Timer.publish(every: 0.1, on: .main, in: .default).autoconnect()
        undoTimer?
            .sink { date in
                self.undoTimeRemaining -= 0.1

                if self.undoTimeRemaining <= -1 {
                    self.undoTimeRemaining = -1
                    self.itemToRemove = nil
                    self.undoTimer?.upstream.connect().cancel()

                    watchlist.remove(itemWith: item.watchlistIdentifier)
                }
            }
            .store(in: &subscriptions)
    }

    func undo() {
        guard let itemToRemove else {
            return
        }

        self.sections[itemToRemove.section]?.unhide(item: itemToRemove)

        self.undoTimeRemaining = -1
        self.itemToRemove = nil
        self.undoTimer?.upstream.connect().cancel()
    }
}
