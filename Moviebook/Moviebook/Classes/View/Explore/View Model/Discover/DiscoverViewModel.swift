//
//  DiscoverViewModel.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 20/04/2023.
//

import Foundation
import SwiftUI
import Combine
import MoviebookCommon

@MainActor final class DiscoverViewModel: ObservableObject {

    // MARK: Instance Properties

    let sectionsContent: [ExploreContentViewModel]

    private var subscriptions: Set<AnyCancellable> = []

    // MARK: Object life cycle

    init() {
        self.sectionsContent = [
            ExploreContentViewModel(dataProvider: DiscoverRelated(), title: "For you", subtitle: "Based on your watchlist", items: .movies([])),
            ExploreContentViewModel(dataProvider: DiscoverCollections(), title: "Collections", subtitle: "Continue watching", items: .movies([])),
            ExploreContentViewModel(dataProvider: DiscoverSection(discoverSection: .popular), title: "Popular", subtitle: nil, items: .movies([])),
            ExploreContentViewModel(dataProvider: DiscoverSection(discoverSection: .nowPlaying), title: "Now playing", subtitle: nil, items: .movies([])),
            ExploreContentViewModel(dataProvider: DiscoverSection(discoverSection: .upcoming), title: "Upcoming", subtitle: nil, items: .movies([])),
            ExploreContentViewModel(dataProvider: DiscoverSection(discoverSection: .topRated), title: "Top rated", subtitle: nil, items: .movies([])),
            ExploreContentViewModel(dataProvider: DiscoverPopularArtists(), title: "Popular artists", subtitle: "Based on your watchlist", items: .artists([]))
        ]
    }

    // MARK: Instance methods

    func start(selectedGenres: Published<Set<MovieGenre>>.Publisher,
               selectedYear: Published<Int?>.Publisher,
               watchlist: Watchlist,
               requestLoader: RequestLoader) {

        Publishers.CombineLatest3(
            selectedGenres,
            selectedYear,
            Publishers.Merge(Just(watchlist.items), watchlist.itemsDidChange)
        )
        .sink { [weak self, weak requestLoader] genres, year, watchlistItems in
            guard let self, let requestLoader else { return }
            Task {
                await self.update(
                    selectedGenres: genres.map(\.id),
                    selectedYear: year,
                    watchlistItems: watchlistItems,
                    requestLoader: requestLoader
                )
            }
        }
        .store(in: &subscriptions)
    }

    private func update(selectedGenres: [MovieGenre.ID],
                        selectedYear: Int?,
                        watchlistItems: [WatchlistItem],
                        requestLoader: RequestLoader) async {
        await withTaskGroup(of: Void.self) { group in
            for content in sectionsContent {
                group.addTask {
                    await content.fetch(requestLoader: requestLoader) { dataProvider in
                        if let forYou = dataProvider as? DiscoverRelated {
                            await forYou.update(
                                referenceMovies: watchlistItems.compactMap(DiscoverRelated.ReferenceMovie.init(watchlistItem:)),
                                genresFilter: selectedGenres,
                                yearFilter: selectedYear,
                                requestLoader: requestLoader
                            )
                        }
                        if let discover = dataProvider as? DiscoverSection {
                            await discover.update(
                                genresFilter: selectedGenres,
                                yearFilter: selectedYear,
                                watchlistItems: watchlistItems
                            )
                        }
                        if let artists = dataProvider as? DiscoverPopularArtists {
                            await artists.update(
                                watchlistItems: watchlistItems,
                                requestLoader: requestLoader
                            )
                        }
                        if let collections = dataProvider as? DiscoverCollections {
                            await collections.update(
                                watchlistItems: watchlistItems,
                                requestLoader: requestLoader
                            )
                        }
                    }
                }
            }
        }
    }
}
