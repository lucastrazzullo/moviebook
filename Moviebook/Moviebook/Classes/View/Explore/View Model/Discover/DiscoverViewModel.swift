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
            ExploreContentViewModel(dataProvider: DiscoverSection(discoverSection: .popular), title: NSLocalizedString("MOVIE.POPULAR", comment: ""), subtitle: nil, items: .movies([])),
            ExploreContentViewModel(dataProvider: DiscoverSection(discoverSection: .nowPlaying), title: NSLocalizedString("MOVIE.NOW_PLAYING", comment: ""), subtitle: nil, items: .movies([])),
            ExploreContentViewModel(dataProvider: DiscoverSection(discoverSection: .upcoming), title: NSLocalizedString("MOVIE.UPCOMING", comment: ""), subtitle: nil, items: .movies([])),
            ExploreContentViewModel(dataProvider: DiscoverSection(discoverSection: .topRated), title: NSLocalizedString("MOVIE.TOP_RATED", comment: ""), subtitle: nil, items: .movies([])),
            ExploreContentViewModel(dataProvider: DiscoverPopularArtists(), title: "Popular artists", subtitle: "Based on your watchlist", items: .artists([]))
        ]
    }

    // MARK: Instance methods

    func start(selectedGenres: Published<Set<MovieGenre>>.Publisher, watchlist: Watchlist, requestManager: RequestManager) {
        Publishers.CombineLatest(selectedGenres, Publishers.Merge(Just(watchlist.items), watchlist.itemsDidChange))
            .sink { [weak self, weak requestManager] genres, watchlistItems in
                guard let self, let requestManager else { return }
                Task {
                    await self.update(selectedGenres: genres.map(\.id), watchlistItems: watchlistItems, requestManager: requestManager)
                }
            }
            .store(in: &subscriptions)
    }

    private func update(selectedGenres: [MovieGenre.ID], watchlistItems: [WatchlistItem], requestManager: RequestManager) async {
        await withTaskGroup(of: Void.self) { group in
            for content in sectionsContent {
                group.addTask {
                    await content.fetch(requestManager: requestManager) { dataProvider in
                        if let forYou = dataProvider as? DiscoverRelated {
                            await forYou.update(genresFilter: selectedGenres, referenceMovies: watchlistItems.compactMap(DiscoverRelated.ReferenceMovie.init(watchlistItem:)), requestManager: requestManager)
                        }
                        if let discover = dataProvider as? DiscoverSection {
                            await discover.update(genresFilter: selectedGenres, watchlistItems: watchlistItems)
                        }
                        if let artists = dataProvider as? DiscoverPopularArtists {
                            await artists.update(watchlistItems: watchlistItems, requestManager: requestManager)
                        }
                    }
                }
            }
        }
    }
}
