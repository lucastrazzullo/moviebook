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
            ExploreContentViewModel(dataProvider: DiscoverForYou()),
            ExploreContentViewModel(dataProvider: DiscoverSection(discoverSection: .popular)),
            ExploreContentViewModel(dataProvider: DiscoverSection(discoverSection: .nowPlaying)),
            ExploreContentViewModel(dataProvider: DiscoverSection(discoverSection: .upcoming)),
            ExploreContentViewModel(dataProvider: DiscoverSection(discoverSection: .topRated)),
            ExploreContentViewModel(dataProvider: DiscoverPopularArtists())
        ]
    }

    // MARK: Instance methods

    func start(selectedGenres: Published<Set<MovieGenre>>.Publisher, watchlist: Watchlist, requestManager: RequestManager) {
        Publishers.CombineLatest(selectedGenres, watchlist.$items)
            .sink { [weak self, weak requestManager] genres, watchlistItems in
                guard let self, let requestManager else { return }
                Task {
                    await self.update(selectedGenres: genres,
                                      watchlistItems: watchlistItems,
                                      requestManager: requestManager)
                }
            }
            .store(in: &subscriptions)
    }

    private func update(selectedGenres: Set<MovieGenre>, watchlistItems: [WatchlistItem], requestManager: RequestManager) async {
        await withTaskGroup(of: Void.self) { group in
            for content in sectionsContent {
                group.addTask {
                    await content.updateDataProvider { dataProvider in
                        if let discoverSection = dataProvider as? DiscoverSection {
                            discoverSection.genresFilter = selectedGenres.map(\.id)
                        }
                        if let forYouSection = dataProvider as? DiscoverForYou {
                            await forYouSection.update(watchlistItems: watchlistItems, requestManager: requestManager)
                        }
                    }

                    await content.fetch(requestManager: requestManager)
                }
            }
        }
    }
}
