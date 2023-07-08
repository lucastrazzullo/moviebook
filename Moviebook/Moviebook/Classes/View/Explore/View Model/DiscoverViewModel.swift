//
//  DiscoverViewModel.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 20/04/2023.
//

import Foundation
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
        var discoverGenre: MovieGenre.ID?

        init(discoverSection: DiscoverMovieSection, discoverGenre: MovieGenre.ID?) {
            self.discoverSection = discoverSection
            self.discoverGenre = discoverGenre
        }

        // MARK: ExploreContentDataProvider

        func fetch(requestManager: RequestManager, page: Int?) async throws -> (results: ExploreContentItems, nextPage: Int?) {
            let response = try await WebService
                .movieWebService(requestManager: requestManager)
                .fetch(discoverSection: discoverSection, genre: discoverGenre, page: page)

            return (results: .movies(response.results), nextPage: response.nextPage)
        }
    }

    // MARK: Instance Properties

    @Published var genre: MovieGenre?

    let sectionsContent: [ExploreContentViewModel]

    private let sections: [DiscoverSection]
    private var subscriptions: Set<AnyCancellable> = []

    // MARK: Object life cycle

    init() {
        self.sections = DiscoverMovieSection.allCases.map { section in
            DiscoverSection(discoverSection: section, discoverGenre: nil)
        }
        self.sectionsContent = sections.map { discoverSection in
            ExploreContentViewModel(dataProvider: discoverSection)
        }
    }

    // MARK: Instance methods

    func start(requestManager: RequestManager) {
        $genre
            .sink { [weak self, weak requestManager] genre in
                guard let self, let requestManager else { return }

                for section in sections {
                    section.discoverGenre = genre?.id
                }
                for content in sectionsContent {
                    content.fetch(requestManager: requestManager)
                }
            }
            .store(in: &subscriptions)
    }
}
