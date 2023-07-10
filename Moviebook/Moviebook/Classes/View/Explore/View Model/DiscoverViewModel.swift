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

        let discoverSection: DiscoverMovieSection
        var discoverGenres: [MovieGenre.ID]

        init(discoverSection: DiscoverMovieSection, discoverGenres: [MovieGenre.ID] = []) {
            self.discoverSection = discoverSection
            self.discoverGenres = discoverGenres
        }

        // MARK: ExploreContentDataProvider

        func fetch(requestManager: RequestManager, page: Int?) async throws -> (results: ExploreContentItems, nextPage: Int?) {
            let response = try await WebService
                .movieWebService(requestManager: requestManager)
                .fetch(discoverSection: discoverSection, genres: discoverGenres, page: page)

            return (results: .movies(response.results), nextPage: response.nextPage)
        }
    }

    final class PopularArtists: Identifiable, ExploreContentDataProvider {

        var title: String {
            return "Popular artists"
        }

        func fetch(requestManager: RequestManager, page: Int?) async throws -> (results: ExploreContentItems, nextPage: Int?) {
            let response = try await WebService
                .artistWebService(requestManager: requestManager)
                .fetchPopular(page: page)

            return (results: .artists(response.results), nextPage: response.nextPage)
        }
    }

    final class ForYou: Identifiable, ExploreContentDataProvider {

        private var watchlistMovies: [Movie.ID] = []
        private var watchlistPopularGenres: [MovieGenre.ID] = []

        var title: String {
            return "For you"
        }

        func fetch(requestManager: RequestManager, page: Int?) async throws -> (results: ExploreContentItems, nextPage: Int?) {
            guard !watchlistPopularGenres.isEmpty else {
                return (results: .movies([]), nextPage: nil)
            }

            let response = try await WebService
                .movieWebService(requestManager: requestManager)
                .fetchMovies(genres: watchlistPopularGenres, page: page)

            let movieIdsSet = Set(watchlistMovies)
            let results = response.results.filter { !movieIdsSet.contains($0.id) }

            return (results: .movies(results), nextPage: response.nextPage)
        }

        func update(watchlistItems: [WatchlistItem], requestManager: RequestManager) async {
            watchlistMovies = watchlistItems
                .compactMap { item in if case .movie(let id) = item.id { return id } else { return nil }}

            watchlistPopularGenres = await withTaskGroup(of: [MovieGenre.ID].self) { group in
                for movieId in watchlistMovies {
                    group.addTask {
                        let movie = try? await WebService.movieWebService(requestManager: requestManager).fetchMovie(with: movieId)
                        return movie?.genres.map(\.id) ?? []
                    }
                }

                var genres: [MovieGenre.ID] = []
                for await response in group {
                    genres.append(contentsOf: response)
                }

                var genresOccourrences: [MovieGenre.ID: Int] = [:]
                for genre in genres {
                    genresOccourrences[genre] = (genresOccourrences[genre] ?? 0) + 1
                }

                let sortedGenres = genresOccourrences.keys.sorted(by: { lhs, rhs in
                    return genresOccourrences[lhs] ?? 0 > genresOccourrences[rhs] ?? 0
                })

                if sortedGenres.count > 3 {
                    return Array(sortedGenres[0..<3])
                } else {
                    return sortedGenres
                }
            }
        }
    }

    // MARK: Instance Properties

    @Published private(set) var sectionsContent: [ExploreContentViewModel] = []

    private var sections: [ExploreContentDataProvider] = []

    private var updateTask: Task<Void, Never>?
    private var subscriptions: Set<AnyCancellable> = []

    // MARK: Object life cycle

    init() {
        self.sections = [
            ForYou(),
            DiscoverSection(discoverSection: .popular),
            DiscoverSection(discoverSection: .nowPlaying),
            DiscoverSection(discoverSection: .upcoming),
            DiscoverSection(discoverSection: .topRated),
            PopularArtists()
        ]
        self.sectionsContent = sections.map { content in
            ExploreContentViewModel(dataProvider: content)
        }
    }

    // MARK: Instance methods

    func start(selectedGenres: Published<Set<MovieGenre>>.Publisher, watchlist: Watchlist, requestManager: RequestManager) {
        Publishers.CombineLatest(selectedGenres, watchlist.$items)
            .sink { [weak self, weak requestManager] genres, watchlistItems in
                guard let self, let requestManager else { return }
                self.updateTask?.cancel()
                self.updateTask = Task {
                    await self.update(selectedGenres: genres,
                                      watchlistItems: watchlistItems,
                                      requestManager: requestManager)
                }
            }
            .store(in: &subscriptions)
    }

    private func update(selectedGenres: Set<MovieGenre>, watchlistItems: [WatchlistItem], requestManager: RequestManager) async {
        for section in sections {
            if let discoverSection = section as? DiscoverSection {
                discoverSection.discoverGenres = selectedGenres.map(\.id)
            }
            if let discoverSection = section as? ForYou {
                await discoverSection.update(watchlistItems: watchlistItems, requestManager: requestManager)
            }
        }

        guard let updateTask, !updateTask.isCancelled else { return }

        for content in sectionsContent {
            content.fetch(requestManager: requestManager)
        }
    }
}
