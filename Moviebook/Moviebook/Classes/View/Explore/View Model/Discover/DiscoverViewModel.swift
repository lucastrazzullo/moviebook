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
        watchlist.$items
            .sink { [weak self, weak requestManager] watchlistItems in
                guard let self, let requestManager else { return }
                Task {
                    await self.update(watchlistItems: watchlistItems, requestManager: requestManager)
                }
            }
            .store(in: &subscriptions)

        selectedGenres
            .sink { [weak self, weak requestManager] genres in
                guard let self, let requestManager else { return }
                Task {
                    await self.update(selectedGenres: genres, requestManager: requestManager)
                }
            }
            .store(in: &subscriptions)
    }

    private func update(watchlistItems: [WatchlistItem], requestManager: RequestManager) async {
        await withTaskGroup(of: Void.self) { group in
            for content in sectionsContent {
                if let forYouSection = content.dataProvider as? DiscoverForYou {
                    group.addTask {
                        await content.update(requestManager: requestManager) {
                            await forYouSection.update(watchlistItems: watchlistItems, requestManager: requestManager)
                        }
                    }
                }
            }
        }
    }

    private func update(selectedGenres: Set<MovieGenre>, requestManager: RequestManager) async {
        await withTaskGroup(of: Void.self) { group in
            for content in sectionsContent {
                if let discoverSection = content.dataProvider as? DiscoverSection {
                    group.addTask {
                        await content.update(requestManager: requestManager) {
                            discoverSection.genresFilter = selectedGenres.map(\.id)
                        }
                    }
                }
            }
        }
    }
}
