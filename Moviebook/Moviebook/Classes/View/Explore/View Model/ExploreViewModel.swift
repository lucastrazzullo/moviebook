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

        func fetch(requestManager: RequestManager, page: Int?) async throws -> (results: ExploreContentItems, nextPage: Int?) {
            let response: (results: [MovieDetails], nextPage: Int?)
            switch self {
            case .nowPlaying:
                response = try await WebService.movieWebService(requestManager: requestManager).fetchNowPlaying(page: page)
            case .upcoming:
                response = try await WebService.movieWebService(requestManager: requestManager).fetchUpcoming(page: page)
            case .popular:
                response = try await WebService.movieWebService(requestManager: requestManager).fetchPopular(page: page)
            case .topRated:
                response = try await WebService.movieWebService(requestManager: requestManager).fetchTopRated(page: page)
            }
            return (results: .movies(response.results), nextPage: response.nextPage)
        }
    }

    // MARK: Instance Properties

    @Published var sections: [ExploreContentViewModel] = Section.allCases.map { section in
        ExploreContentViewModel(title: section.title, dataProvider: section)
    }

    private var subscriptions: Set<AnyCancellable> = []

    // MARK: Instance methods

    func start(requestManager: RequestManager) {
        for section in sections {
            section.fetch(requestManager: requestManager)
            section.objectWillChange
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    self?.objectWillChange.send()
                }
                .store(in: &subscriptions)
        }
    }
}
