//
//  ExploreViewModel.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 20/04/2023.
//

import Foundation
import Combine
import MoviebookCommon

@MainActor final class ExploreViewModel: ObservableObject {

    // MARK: Types

    enum Section: String, Identifiable, CaseIterable, ExploreContentDataProvider {
        case nowPlaying
        case upcoming
        case popular
        case topRated

        var id: String {
            return rawValue
        }

        var title: String {
            switch self {
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

        func fetch(requestManager: RequestManager, genre: MovieGenre.ID?, page: Int?) async throws -> (results: ExploreContentItems, nextPage: Int?) {
            let response: (results: [MovieDetails], nextPage: Int?)
            switch self {
            case .nowPlaying:
                response = try await WebService.movieWebService(requestManager: requestManager).fetch(discoverSection: .nowPlaying, genre: genre, page: page)
            case .upcoming:
                response = try await WebService.movieWebService(requestManager: requestManager).fetch(discoverSection: .upcoming, genre: genre, page: page)
            case .popular:
                response = try await WebService.movieWebService(requestManager: requestManager).fetch(discoverSection: .popular, genre: genre, page: page)
            case .topRated:
                response = try await WebService.movieWebService(requestManager: requestManager).fetch(discoverSection: .topRated, genre: genre, page: page)
            }
            return (results: .movies(response.results), nextPage: response.nextPage)
        }
    }

    // MARK: Instance Properties

    @Published var sections: [ExploreContentViewModel] = Section.allCases.map { section in
        ExploreContentViewModel(title: section.title, dataProvider: section)
    }

    @Published var genre: MovieGenre?

    private var subscriptions: Set<AnyCancellable> = []

    // MARK: Instance methods

    func start(requestManager: RequestManager) {
        $genre
            .sink { [weak self, weak requestManager] genre in
                guard let self, let requestManager else { return }

                for section in sections {
                    section.fetch(requestManager: requestManager, genre: genre?.id)
                    section.objectWillChange
                        .receive(on: DispatchQueue.main)
                        .sink { [weak self] _ in
                            self?.objectWillChange.send()
                        }
                        .store(in: &subscriptions)
                }
            }
            .store(in: &subscriptions)
    }
}
