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

    // MARK: Types

    final class DiscoverSection: Identifiable, ExploreContentDataProvider {

        var id: String {
            return title
        }

        var title: String {
            switch discoverSection {
            case .nowPlaying:
                return NSLocalizedString("MOVIE.NOW_PLAYING", comment: "")
            case .upcoming:
                return NSLocalizedString("MOVIE.UPCOMING", comment: "")
            case .popular:
                return NSLocalizedString("MOVIE.POPULAR", comment: "")
            case .topRated:
                return NSLocalizedString("MOVIE.TOP_RATED", comment: "")
            }
        }

        let subtitle: String? = nil
        var genresFilter: [MovieGenre.ID]

        private let discoverSection: DiscoverMovieSection

        init(discoverSection: DiscoverMovieSection, discoverGenres: [MovieGenre.ID] = []) {
            self.discoverSection = discoverSection
            self.genresFilter = discoverGenres
        }

        // MARK: ExploreContentDataProvider

        func fetch(requestManager: RequestManager, page: Int?) async throws -> (results: ExploreContentItems, nextPage: Int?) {
            let response = try await WebService
                .movieWebService(requestManager: requestManager)
                .fetchMovies(discoverSection: discoverSection, genres: genresFilter, page: page)

            return (results: .movies(response.results), nextPage: response.nextPage)
        }
    }

    final class PopularArtists: Identifiable, ExploreContentDataProvider {

        var title: String {
            return "Popular artists"
        }

        let subtitle: String? = nil

        func fetch(requestManager: RequestManager, page: Int?) async throws -> (results: ExploreContentItems, nextPage: Int?) {
            let response = try await WebService
                .artistWebService(requestManager: requestManager)
                .fetchPopular(page: page)

            return (results: .artists(response.results), nextPage: response.nextPage)
        }
    }

    final class ForYou: Identifiable, ExploreContentDataProvider {

        struct WatchlistMovie {

            enum Weight {
                case exceptional
                case important
                case neutral
                case unwanted
            }

            let id: Movie.ID
            let weight: Weight

            init?(watchlistItem: WatchlistItem) {
                guard case .movie(let movieId) = watchlistItem.id else {
                    return nil
                }

                if case .watched(let info) = watchlistItem.state, let rating = info.rating {
                    self.weight = rating >= 9
                        ? .exceptional
                        : rating >= 7
                            ? .important
                            : rating < 6
                                ? .unwanted
                                : .neutral
                } else {
                    self.weight = .neutral
                }

                self.id = movieId
            }
        }

        let title: String = "For you"
        let subtitle: String? = "based on your watchlist"

        private var watchlistMovies: [WatchlistMovie] = []
        private var watchlistPopularKeywords: [MovieKeyword.ID] = []
        private var watchlistPopularGenres: [MovieGenre.ID] = []

        func fetch(requestManager: RequestManager, page: Int?) async throws -> (results: ExploreContentItems, nextPage: Int?) {
            if watchlistPopularGenres.isEmpty && watchlistPopularKeywords.isEmpty {
                return (results: .movies([]), nextPage: nil)
            }

            let response = try await WebService
                .movieWebService(requestManager: requestManager)
                .fetchMovies(keywords: watchlistPopularKeywords,
                             genres: watchlistPopularGenres,
                             page: page)

            let movieIdsSet = Set(watchlistMovies.map(\.id))
            let results = response.results.filter { !movieIdsSet.contains($0.id) }

            return (results: .movies(results), nextPage: response.nextPage)
        }

        func update(watchlistItems: [WatchlistItem], requestManager: RequestManager) async {
            watchlistMovies = watchlistItems.compactMap(WatchlistMovie.init(watchlistItem:))

            watchlistPopularKeywords = await withTaskGroup(of: [MovieKeyword.ID].self) { group in
                for watchlistMovie in watchlistMovies {
                    group.addTask {
                        if case .unwanted = watchlistMovie.weight {
                            return []
                        }

                        guard let keywords = try? await WebService.movieWebService(requestManager: requestManager)
                            .fetchMovieKeywords(with: watchlistMovie.id) else {
                            return []
                        }

                        switch watchlistMovie.weight {
                        case .exceptional:
                            return (keywords+keywords+keywords+keywords).map(\.id)
                        case .important:
                            return (keywords+keywords).map(\.id)
                        case .neutral:
                            return keywords.map(\.id)
                        case .unwanted:
                            return []
                        }
                    }
                }

                var keywords: [MovieKeyword.ID] = []
                for await response in group {
                    keywords.append(contentsOf: response)
                }

                return getMostPopular(items: keywords, cap: 3)
            }

            watchlistPopularGenres = await withTaskGroup(of: [MovieGenre.ID].self) { group in
                for watchlistMovie in watchlistMovies {
                    group.addTask {
                        if case .unwanted = watchlistMovie.weight {
                            return []
                        }

                        guard let genres = try? await WebService.movieWebService(requestManager: requestManager)
                            .fetchMovie(with: watchlistMovie.id).genres else {
                            return []
                        }

                        switch watchlistMovie.weight {
                        case .exceptional:
                            return (genres+genres+genres+genres).map(\.id)
                        case .important:
                            return (genres+genres).map(\.id)
                        case .neutral:
                            return genres.map(\.id)
                        case .unwanted:
                            return []
                        }
                    }
                }

                var genres: [MovieGenre.ID] = []
                for await response in group {
                    genres.append(contentsOf: response)
                }

                return getMostPopular(items: genres, cap: 3)
            }
        }

        private func getMostPopular<Item: Hashable>(items: [Item], cap: Int) -> [Item] {
            var itemsOccurrences: [Item: Int] = [:]
            for item in items {
                itemsOccurrences[item] = (itemsOccurrences[item] ?? 0) + 1
            }

            let sortedItems = itemsOccurrences.keys.sorted(by: { lhs, rhs in
                return itemsOccurrences[lhs] ?? 0 > itemsOccurrences[rhs] ?? 0
            })

            if sortedItems.count > cap {
                return Array(sortedItems[0..<cap])
            } else {
                return sortedItems
            }
        }
    }

    // MARK: Instance Properties

    let sectionsContent: [ExploreContentViewModel]

    private var subscriptions: Set<AnyCancellable> = []

    // MARK: Object life cycle

    init() {
        self.sectionsContent = [
            ExploreContentViewModel(dataProvider: ForYou()),
            ExploreContentViewModel(dataProvider: DiscoverSection(discoverSection: .popular)),
            ExploreContentViewModel(dataProvider: DiscoverSection(discoverSection: .nowPlaying)),
            ExploreContentViewModel(dataProvider: DiscoverSection(discoverSection: .upcoming)),
            ExploreContentViewModel(dataProvider: DiscoverSection(discoverSection: .topRated)),
            ExploreContentViewModel(dataProvider: PopularArtists())
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
                    if let discoverSection = content.dataProvider as? DiscoverSection {
                        discoverSection.genresFilter = selectedGenres.map(\.id)
                    }
                    if let forYouSection = content.dataProvider as? ForYou {
                        await forYouSection.update(watchlistItems: watchlistItems, requestManager: requestManager)
                    }

                    await content.fetch(requestManager: requestManager)
                }
            }
        }
    }
}
